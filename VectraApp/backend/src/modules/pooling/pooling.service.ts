import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { RideRequestStatus, RideType, VehicleType } from '../ride_requests/ride-request.enums';
import { PoolGroupEntity, PoolStatus } from './pool-group.entity';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripRiderEntity, TripRiderStatus } from '../trips/trip-rider.entity';
import { MlClientService } from '../../integrations/ml-client/ml-client.service';
import { getLatitude, getLongitude } from '../../common/types/geo-point.type';

// ─── Haversine helpers ────────────────────────────────────────────────────────

function haversineMeters(
  lat1: number, lng1: number,
  lat2: number, lng2: number,
): number {
  const R = 6_371_000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

interface GeoCoord { lat: number; lng: number }

function dist(a: GeoCoord, b: GeoCoord): number {
  return haversineMeters(a.lat, a.lng, b.lat, b.lng);
}

/**
 * Pooling constraints
 * ─────────────────────────────────────────────────────────────────────────────
 * Detour budget: max extra distance added to ANY rider's trip ≤ 4 000 m
 *                (≈ 10 min at 24 km/h city speed).
 * Angle check:   bearing between pickup A and pickup B must be < 90° from
 *                the A→dropoff heading (same direction of travel).
 */
const MAX_DETOUR_METERS = 4_000;
const MAX_WAIT_SECONDS  = 600;   // 10 min — max extra time per rider

/**
 * Estimate extra travel seconds for picking up a new rider.
 * Assumes average city speed of 24 km/h.
 */
function detourSeconds(extraMeters: number): number {
  return (extraMeters / 24_000) * 3600;
}

interface PoolEvalResult {
  valid: boolean;
  extraMetersForAnchor: number;
  sequence: Array<{ riderId: string; type: 'pickup' | 'dropoff' }>;
}

/**
 * Evaluate whether adding `candidate` to an existing pool anchored by `anchor`
 * is within the detour budget.
 *
 * Route order checked (two permutations):
 *   A) anchor.pickup → cand.pickup → cand.dropoff → anchor.dropoff
 *   B) anchor.pickup → cand.pickup → anchor.dropoff → cand.dropoff
 *
 * Baseline: anchor.pickup → anchor.dropoff
 *
 * The permutation with the minimum extra distance is chosen.
 */
function evaluateDetour(
  anchor: { pickup: GeoCoord; dropoff: GeoCoord; riderId: string },
  candidate: { pickup: GeoCoord; dropoff: GeoCoord; riderId: string },
): PoolEvalResult {
  const baseline = dist(anchor.pickup, anchor.dropoff);

  // Permutation A: pickup cand first, then drop cand, then anchor drop
  const routeA =
    dist(anchor.pickup, candidate.pickup) +
    dist(candidate.pickup, candidate.dropoff) +
    dist(candidate.dropoff, anchor.dropoff);

  // Permutation B: pickup cand first, drop anchor first, then drop cand
  const routeB =
    dist(anchor.pickup, candidate.pickup) +
    dist(candidate.pickup, anchor.dropoff) +
    dist(anchor.dropoff, candidate.dropoff);

  const bestRoute = Math.min(routeA, routeB);
  const extraForAnchor = bestRoute - baseline;

  const useA = routeA <= routeB;
  const sequence = useA
    ? [
        { riderId: candidate.riderId, type: 'pickup' as const },
        { riderId: candidate.riderId, type: 'dropoff' as const },
        { riderId: anchor.riderId,    type: 'dropoff' as const },
      ]
    : [
        { riderId: candidate.riderId, type: 'pickup' as const },
        { riderId: anchor.riderId,    type: 'dropoff' as const },
        { riderId: candidate.riderId, type: 'dropoff' as const },
      ];

  return {
    valid:
      extraForAnchor <= MAX_DETOUR_METERS &&
      detourSeconds(extraForAnchor) <= MAX_WAIT_SECONDS,
    extraMetersForAnchor: extraForAnchor,
    sequence,
  };
}

// ─── Service ──────────────────────────────────────────────────────────────────

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
    private readonly mlClient: MlClientService,
  ) { }

  // ─── 1. Find Candidates ────────────────────────────────────────────────────

  /**
   * Find pending POOL requests near the anchor request using PostGIS ST_DWithin.
   * Bikes never pool. Applies vehicle-type and status filters.
   */
  async findCandidates(
    request: RideRequestEntity,
    currentRadiusMeters: number,
  ): Promise<RideRequestEntity[]> {
    if (request.vehicleType === VehicleType.BIKE) return [];

    return this.requestRepo
      .createQueryBuilder('request')
      .where('request.status = :status', { status: RideRequestStatus.REQUESTED })
      .andWhere('request.ride_type = :rideType', { rideType: RideType.POOL })
      .andWhere('request.vehicle_type = :vehicleType', { vehicleType: request.vehicleType })
      .andWhere('request.id != :selfId', { selfId: request.id })
      .andWhere(
        `ST_DWithin(
           request.pickup_point,
           ST_SetSRID(ST_GeomFromGeoJSON(:pickupPoint), 4326)::geography,
           :radius
         )`,
        {
          pickupPoint: JSON.stringify(request.pickupPoint),
          radius: currentRadiusMeters,
        },
      )
      .orderBy('request.requested_at', 'ASC') // oldest waiters first
      .limit(10)
      .getMany();
  }

  // ─── 2. Evaluate Groupings ─────────────────────────────────────────────────

  /**
   * Evaluate whether a set of candidates can pool with the anchor request.
   *
   * Strategy:
   *   1. Try the Python ML service (fast, uses road distances).
   *   2. If ML is unavailable, fall back to the Haversine-based detour check.
   *
   * This ensures the system always makes a decision — no silent failures.
   */
  async evaluateGroupings(
    mainRequest: RideRequestEntity,
    candidates: RideRequestEntity[],
  ): Promise<{
    riders: RideRequestEntity[];
    sequence?: Array<{ riderId: string; type: 'pickup' | 'dropoff' }>;
  } | null> {
    if (candidates.length === 0) return null;

    const maxRiders = mainRequest.vehicleType === VehicleType.AUTO ? 3 : 4;
    const potentialGroup = [mainRequest, ...candidates.slice(0, maxRiders - 1)];

    // ── Try ML service first ──────────────────────────────────────────────────
    try {
      const evaluation = await this.mlClient.evaluatePool({
        vehicle_type: mainRequest.vehicleType,
        riders: potentialGroup.map((r) => ({
          id: r.id,
          lat: getLatitude(r.pickupPoint),
          lng: getLongitude(r.pickupPoint),
          drop_lat: getLatitude(r.dropPoint),
          drop_lng: getLongitude(r.dropPoint),
        })),
      });

      if (evaluation.isValid && evaluation.detourOk) {
        this.logger.debug(`ML service approved pool for request ${mainRequest.id}`);
        return { riders: potentialGroup };
      }

      // ML says NO — but also apply our own check in case ML is being conservative
    } catch (err) {
      this.logger.warn(
        `ML service unavailable (${(err as Error).message}), falling back to Haversine detour check`,
      );
    }

    // ── Haversine fallback ────────────────────────────────────────────────────
    const anchor = {
      riderId: mainRequest.id,
      pickup: {
        lat: getLatitude(mainRequest.pickupPoint),
        lng: getLongitude(mainRequest.pickupPoint),
      },
      dropoff: {
        lat: getLatitude(mainRequest.dropPoint),
        lng: getLongitude(mainRequest.dropPoint),
      },
    };

    for (const candidate of candidates) {
      const cand = {
        riderId: candidate.id,
        pickup: {
          lat: getLatitude(candidate.pickupPoint),
          lng: getLongitude(candidate.pickupPoint),
        },
        dropoff: {
          lat: getLatitude(candidate.dropPoint),
          lng: getLongitude(candidate.dropPoint),
        },
      };

      const result = evaluateDetour(anchor, cand);

      if (result.valid) {
        this.logger.debug(
          `Haversine approved pool: ${mainRequest.id} + ${candidate.id} ` +
          `(extra ${Math.round(result.extraMetersForAnchor)}m ` +
          `≈ ${Math.round(detourSeconds(result.extraMetersForAnchor))}s)`,
        );
        return { riders: [mainRequest, candidate], sequence: result.sequence };
      }
    }

    this.logger.debug(`No valid pool found for request ${mainRequest.id}`);
    return null;
  }

  // ─── 3. Finalize Pool ─────────────────────────────────────────────────────

  /**
   * Atomically create the PoolGroup, update request statuses, create Trip, and
   * attach TripRider rows with the correct pickup/dropoff sequences.
   *
   * Uses pessimistic write locks to prevent double-pooling when the cron fires
   * concurrently from multiple instances.
   */
  async finalizePool(grouping: {
    riders: RideRequestEntity[];
    sequence?: Array<{ riderId: string; type: 'pickup' | 'dropoff' }>;
  }): Promise<string | null> {
    const riderRequestIds = grouping.riders.map((r) => r.id);

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Lock rows to prevent race conditions ───────────────────────────────
      const lockedRequests = await queryRunner.manager
        .createQueryBuilder(RideRequestEntity, 'request')
        .setLock('pessimistic_write')
        .whereInIds(riderRequestIds)
        .andWhere('request.status = :status', { status: RideRequestStatus.REQUESTED })
        .getMany();

      if (lockedRequests.length !== riderRequestIds.length) {
        // Some requests were cancelled or already pooled by another cron tick
        await queryRunner.rollbackTransaction();
        this.logger.warn(
          `Pool race detected — only ${lockedRequests.length}/${riderRequestIds.length} requests still available`,
        );
        return null;
      }

      const vehicleType = lockedRequests[0].vehicleType;
      const maxRiders   = vehicleType === VehicleType.AUTO ? 3 : 4;

      // 2. Create PoolGroup ───────────────────────────────────────────────────
      const poolGroup = queryRunner.manager.create(PoolGroupEntity, {
        status: PoolStatus.FORMING,
        vehicleType,
        currentRidersCount: lockedRequests.length,
        maxRiders,
      });
      const savedPool = await queryRunner.manager.save(poolGroup);

      // 3. Build sequence maps for pickup/dropoff ordering ───────────────────
      // If we have an explicit sequence from the detour algorithm, use it.
      // Otherwise assign anchor first, then candidate.
      const pickupOrder  = new Map<string, number>(); // requestId → sequence
      const dropoffOrder = new Map<string, number>();

      if (grouping.sequence && grouping.sequence.length > 0) {
        let pickupSeq  = 1;
        let dropoffSeq = 1;
        for (const step of grouping.sequence) {
          const req = lockedRequests.find((r) => r.id === step.riderId);
          if (!req) continue;
          if (step.type === 'pickup') {
            pickupOrder.set(req.riderUserId, pickupSeq++);
          } else {
            dropoffOrder.set(req.riderUserId, dropoffSeq++);
          }
        }
      } else {
        lockedRequests.forEach((r, idx) => {
          pickupOrder.set(r.riderUserId, idx + 1);
          dropoffOrder.set(r.riderUserId, idx + 1);
        });
      }

      // 4. Update ride requests → POOLED ────────────────────────────────────
      for (const req of lockedRequests) {
        req.poolGroupId = savedPool.id;
        req.status      = RideRequestStatus.POOLED;
        await queryRunner.manager.save(req);
      }

      // 5. Create unassigned Trip (MatchingManager will assign a driver) ──────
      const trip = queryRunner.manager.create(TripEntity, {
        status: TripStatus.REQUESTED,
        vehicleType: lockedRequests[0].vehicleType,
        rideType: RideType.POOL,
      });
      const savedTrip = await queryRunner.manager.save(trip);

      // 6. Create TripRider rows with sequences ─────────────────────────────
      for (const req of lockedRequests) {
        const tripRider = queryRunner.manager.create(TripRiderEntity, {
          tripId:         savedTrip.id,
          riderUserId:    req.riderUserId,
          pickupPoint:    req.pickupPoint,
          dropPoint:      req.dropPoint,
          pickupSequence: pickupOrder.get(req.riderUserId) ?? 1,
          dropSequence:   dropoffOrder.get(req.riderUserId) ?? 1,
          status:         TripRiderStatus.JOINED,
        });
        await queryRunner.manager.save(tripRider);
      }

      await queryRunner.commitTransaction();
      this.logger.log(
        `Pool finalised: group ${savedPool.id}, trip ${savedTrip.id}, ` +
        `${lockedRequests.length} riders`,
      );
      return savedTrip.id;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      this.logger.error('Failed to finalise pool', err);
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}


