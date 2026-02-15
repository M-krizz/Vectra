import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import {
  RideRequestStatus,
  RideType,
  VehicleType,
} from '../ride_requests/ride-request.enums';
import { PoolGroupEntity, PoolStatus } from './pool-group.entity';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripRiderEntity, TripRiderStatus } from '../trips/trip-rider.entity';
// import { MlClientService } from '../../integrations/ml-client/ml-client.service'; // TODO: Implement ML Client

export interface PoolingEvaluationResult {
  riders: RideRequestEntity[];
  isValid: boolean;
  score: number;
  sequence: string[];
  detourOk: boolean;
}

@Injectable()
export class PoolingService {
  private readonly logger = new Logger(PoolingService.name);

  constructor(
    @InjectRepository(RideRequestEntity)
    private readonly requestRepo: Repository<RideRequestEntity>,
    @InjectRepository(PoolGroupEntity)
    private readonly poolGroupRepo: Repository<PoolGroupEntity>,
    @InjectRepository(TripEntity)
    private readonly tripRepo: Repository<TripEntity>,
    @InjectRepository(TripRiderEntity)
    private readonly tripRiderRepo: Repository<TripRiderEntity>,
    private readonly dataSource: DataSource,
    // private readonly mlClient: MlClientService,
  ) {}

  /**
   * Adaptive Radius Search for Pooling Candidates
   */
  async findCandidates(
    request: RideRequestEntity,
    currentRadiusMeters: number,
  ): Promise<RideRequestEntity[]> {
    if (request.vehicleType === VehicleType.BIKE) {
      return []; // Bikes don't pool
    }

    // Find other REQUESTED, POOL rides of SAME vehicle type
    // Within radius and within last 2-5 mins (valid window)
    // Exclude self

    // PostGIS ST_DWithin takes degrees if using geometry(4326), but meters if geography(4326).
    // Our entity uses 'geography', so meters works directly.

    const candidates = await this.requestRepo
      .createQueryBuilder('request')
      .where('request.status = :status', {
        status: RideRequestStatus.REQUESTED,
      })
      .andWhere('request.ride_type = :rideType', { rideType: RideType.POOL })
      .andWhere('request.vehicle_type = :vehicleType', {
        vehicleType: request.vehicleType,
      })
      .andWhere('request.id != :selfId', { selfId: request.id })
      .andWhere(
        `ST_DWithin(request.pickup_point, ST_SetSRID(ST_GeomFromGeoJSON(:pickupPoint), 4326)::geography, :radius)`,
        {
          pickupPoint: JSON.stringify(request.pickupPoint),
          radius: currentRadiusMeters,
        },
      )
      .orderBy('request.requested_at', 'DESC') // Newer first? Or older first to prioritize waiters?
      // Efficiency-first: maybe just grab all valid ones.
      .limit(10) // Optimization limit
      .getMany();

    return candidates;
  }

  /**
   * Evaluate potential pool groupings via Python ML Service
   * strict V1 constraints: Max 3 (Auto) / 4 (Cab), <10% detour, <3min wait
   */
  evaluateGroupings(
    mainRequest: RideRequestEntity,
    candidates: RideRequestEntity[],
  ): Promise<PoolingEvaluationResult | null> {
    if (candidates.length === 0) return Promise.resolve(null);

    const maxRiders = mainRequest.vehicleType === VehicleType.AUTO ? 3 : 4;

    // Form groups of size 2 up to maxRiders
    // This is combinatorial. For V1 with small N, we can just try pairing with best candidate first?
    // Or send all to Python and let Python permute?
    // Let's send main + up to (max-1) candidates to Python.

    const potentialGroup = [mainRequest, ...candidates.slice(0, maxRiders - 1)];

    // Call Python Service (Mocked for now)
    // const evaluation = await this.mlClient.evaluatePool({
    //   vehicle_type: mainRequest.vehicleType,
    //   riders: potentialGroup.map(r => ({ ... }))
    // });

    // MOCK RESPONSE
    const mockEvaluation = {
      isValid: true,
      score: 0.9,
      sequence: potentialGroup.map((r) => r.id), // Just sequential for now
      detourOk: true,
    };

    if (mockEvaluation.isValid && mockEvaluation.detourOk) {
      return Promise.resolve({
        riders: potentialGroup,
        ...mockEvaluation,
      });
    }

    return Promise.resolve(null);
  }

  /**
   * Finalize a pool grouping: Lock rows, create Trip, update statuses
   */
  async finalizePool(grouping: {
    riders: RideRequestEntity[];
  }): Promise<string | null> {
    const riderIds = grouping.riders.map((r) => r.id);

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Lock Requests to prevent double-pooling
      const lockedRequests = await queryRunner.manager
        .createQueryBuilder(RideRequestEntity, 'request')
        .setLock('pessimistic_write')
        .whereInIds(riderIds)
        .andWhere('request.status = :status', {
          status: RideRequestStatus.REQUESTED,
        })
        .getMany();

      if (lockedRequests.length !== riderIds.length) {
        // Some requests were snatched by another process or cancelled
        await queryRunner.rollbackTransaction();
        return null;
      }

      // 2. Create PoolGroup
      const poolGroup = this.poolGroupRepo.create({
        status: PoolStatus.FORMING,
        vehicleType: lockedRequests[0].vehicleType, // All same
        currentRidersCount: lockedRequests.length,
        maxRiders: lockedRequests[0].vehicleType === VehicleType.AUTO ? 3 : 4,
      });
      const savedPool = await queryRunner.manager.save(poolGroup);

      // 3. Update Requests
      for (const req of lockedRequests) {
        req.poolGroupId = savedPool.id;
        req.status = RideRequestStatus.MATCHING; // Or POOLED?
        // Logic: They are MATCHING for a driver now as a group.
        // Or "POOLED" status means they are in a pool group?
        // Let's use POOLED to signify "Group Formed, Waiting for Driver".
        req.status = RideRequestStatus.POOLED;
        await queryRunner.manager.save(req);
      }

      // 4. Create Trip (Unassigned)
      // Usually matching happens NEXT.
      // But we need a Trip entity to offer to drivers.
      const trip = this.tripRepo.create({
        status: TripStatus.REQUESTED,
        // No driver yet
      });
      const savedTrip = await queryRunner.manager.save(trip);

      // 5. Create TripRiders
      for (const req of lockedRequests) {
        const tripRider = this.tripRiderRepo.create({
          tripId: savedTrip.id,
          riderUserId: req.riderUserId,
          pickupPoint: req.pickupPoint,
          dropPoint: req.dropPoint,
          status: TripRiderStatus.JOINED,
          // Sequence should come from Python evaluation
          // pickupSequence: ...
          // dropSequence: ...
        });
        await queryRunner.manager.save(tripRider);
      }

      await queryRunner.commitTransaction();
      this.logger.log(
        `Finalized pool ${savedPool.id} with ${lockedRequests.length} riders`,
      );
      return savedTrip.id;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      this.logger.error('Failed to finalize pool', err);
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}
