import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { RideRequestEntity } from './ride-request.entity';
import { RideRequestStatus, RideType, VehicleType } from './ride-request.enums';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { GeoPoint, getLatitude, getLongitude } from '../../common/types/geo-point.type';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripRiderEntity, TripRiderStatus } from '../trips/trip-rider.entity';
import { FareService } from '../fare/fare.service';
import { MapsService } from '../maps/maps.service';
import { LocationGateway } from '../location/location.gateway';

// Haversine fallback for distance estimate
function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number) {
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

@Injectable()
export class RideRequestsService {
  private readonly logger = new Logger(RideRequestsService.name);

  constructor(
    @InjectRepository(RideRequestEntity)
    private readonly rideRequestsRepo: Repository<RideRequestEntity>,
    @InjectRepository(TripEntity)
    private readonly tripRepo: Repository<TripEntity>,
    @InjectRepository(TripRiderEntity)
    private readonly tripRiderRepo: Repository<TripRiderEntity>,
    private readonly dataSource: DataSource,
    private readonly fareService: FareService,
    private readonly mapsService: MapsService,
    private readonly locationGateway: LocationGateway,
  ) { }

  /**
   * Create a ride request.
   * For SOLO rides: immediately creates a Trip + TripRider so the MatchingManager
   * can broadcast the offer to nearby drivers within seconds.
   * For POOL rides: the PoolingManager handles trip creation after grouping.
   *
   * Returns the request plus `tripId` (SOLO) and `estimatedFare` (all rides).
   */
  async createRequest(
    userId: string,
    dto: CreateRideRequestDto,
  ): Promise<RideRequestEntity & { tripId?: string; estimatedFare?: number }> {
    const vehicleType = dto.vehicleType || VehicleType.AUTO;

    // ── Estimate distance for fare calc ──────────────────────────────────────
    let distanceMeters = 0;
    try {
      const route = await this.mapsService.getEtaAndDistance(
        dto.pickupPoint as GeoPoint,
        dto.dropPoint as GeoPoint,
      );
      distanceMeters = route.distanceMeters;
    } catch {
      const pLat = getLatitude(dto.pickupPoint as GeoPoint);
      const pLng = getLongitude(dto.pickupPoint as GeoPoint);
      const dLat = getLatitude(dto.dropPoint as GeoPoint);
      const dLng = getLongitude(dto.dropPoint as GeoPoint);
      distanceMeters = Math.round(haversineMeters(pLat, pLng, dLat, dLng));
    }

    const fareBreakdown = this.fareService.estimate(
      vehicleType,
      dto.rideType,
      distanceMeters,
    );

    // ── Transaction ───────────────────────────────────────────────────────────
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRequest = this.rideRequestsRepo.create({
        riderUserId: userId,
        pickupPoint: dto.pickupPoint as GeoPoint,
        dropPoint: dto.dropPoint as GeoPoint,
        pickupAddress: dto.pickupAddress,
        dropAddress: dto.dropAddress,
        rideType: dto.rideType,
        vehicleType,
        status: RideRequestStatus.REQUESTED,
        requestedAt: new Date(),
        expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5-minute TTL
      });

      const savedRequest = await queryRunner.manager.save(rideRequest);

      let tripId: string | undefined;

      // ── SOLO: create Trip immediately so the matching loop picks it up ──────
      if (dto.rideType === RideType.SOLO) {
        const trip = queryRunner.manager.create(TripEntity, {
          status: TripStatus.REQUESTED,
          vehicleType,
          rideType: RideType.SOLO,
          distanceMeters,
        });
        const savedTrip = await queryRunner.manager.save(trip);
        tripId = savedTrip.id;

        const tripRider = queryRunner.manager.create(TripRiderEntity, {
          tripId: savedTrip.id,
          riderUserId: userId,
          pickupPoint: dto.pickupPoint as GeoPoint,
          dropPoint: dto.dropPoint as GeoPoint,
          pickupSequence: 1,
          dropSequence: 1,
          status: TripRiderStatus.JOINED,
        });
        await queryRunner.manager.save(tripRider);

        // Mark the request as MATCHING so the pooling loop doesn't try to pool it
        savedRequest.status = RideRequestStatus.MATCHING;
        await queryRunner.manager.save(savedRequest);

        this.logger.log(
          `SOLO ride request ${savedRequest.id} → trip ${savedTrip.id} created`,
        );
      }

      await queryRunner.commitTransaction();

      // ── Notify rider to join their trip room so socket events reach them ────
      if (tripId) {
        this.locationGateway.server
          ?.to(`user:${userId}`)
          .emit('trip_created', {
            tripId,
            requestId: savedRequest.id,
            estimatedFare: fareBreakdown.perRiderFare,
          });
      }

      return { ...savedRequest, tripId, estimatedFare: fareBreakdown.perRiderFare };
    } catch (err) {
      await queryRunner.rollbackTransaction();
      this.logger.error('Failed to create ride request', err);
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getRequest(id: string): Promise<RideRequestEntity | null> {
    return this.rideRequestsRepo.findOne({ where: { id } });
  }

  async getActiveRequestForUser(
    userId: string,
  ): Promise<RideRequestEntity | null> {
    return this.rideRequestsRepo.findOne({
      where: {
        riderUserId: userId,
        status: RideRequestStatus.REQUESTED,
      },
      order: { requestedAt: 'DESC' },
    });
  }

  async cancelRequest(id: string, userId: string): Promise<void> {
    await this.rideRequestsRepo.update(
      { id, riderUserId: userId },
      { status: RideRequestStatus.CANCELLED },
    );
  }
}
