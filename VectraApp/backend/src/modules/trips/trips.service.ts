import { Injectable, NotFoundException, BadRequestException, Logger, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity, TripStatus } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { TripRiderEntity } from './trip-rider.entity';
import { LocationGateway } from '../location/location.gateway';
import { FareService } from '../fare/fare.service';
import { RideType } from '../ride_requests/ride-request.enums';
import Redis from 'ioredis';
import { REDIS } from '../../integrations/redis/redis.module';
import { DriverProfileEntity } from '../Authentication/drivers/driver-profile.entity';
import { PaymentsService } from '../payments/payments.service';
import { PaymentMethod } from '../payments/entities/payment.entity';

/** Infer RideType from rider count. */
function ride_type_from_count(count: number): RideType {
  return count > 1 ? RideType.POOL : RideType.SOLO;
}

@Injectable()
export class TripsService {
  private readonly logger = new Logger(TripsService.name);

  constructor(
    @InjectRepository(TripEntity)
    private readonly tripRepo: Repository<TripEntity>,
    @InjectRepository(TripEventEntity)
    private readonly eventRepo: Repository<TripEventEntity>,
    @InjectRepository(TripRiderEntity)
    private readonly tripRiderRepo: Repository<TripRiderEntity>,
    @InjectRepository(DriverProfileEntity)
    private readonly driverProfileRepo: Repository<DriverProfileEntity>,
    @Inject(REDIS) private readonly redisClient: Redis,
    @Inject(forwardRef(() => LocationGateway)) private readonly locationGateway: LocationGateway,
    private readonly fareService: FareService,
    @Inject(forwardRef(() => PaymentsService)) private readonly paymentsService: PaymentsService,
  ) { }

  async getTrip(id: string) {
    const trip = await this.tripRepo.findOne({
      where: { id },
      relations: ['driver', 'tripRiders', 'tripRiders.rider'],
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    // Fetch latest location event
    const latestLocation = await this.eventRepo.findOne({
      where: { tripId: id, eventType: 'DRIVER_LOCATION' },
      order: { createdAt: 'DESC' },
    });

    return {
      ...trip,
      latestLocation: latestLocation?.metadata || null,
    };
  }

  /**
   * Fetch all trips for a specific user (Rider or Driver)
   */
  async getUserTrips(userId: string, role: string) {
    if (role === 'DRIVER') {
      return this.tripRepo.find({
        where: { driver: { id: userId } as any },
        relations: ['driver', 'tripRiders', 'tripRiders.rider'],
        order: { createdAt: 'DESC' },
      });
    } else {
      // Rider
      return this.tripRepo.find({
        where: { tripRiders: { riderUserId: userId } },
        relations: ['driver', 'tripRiders', 'tripRiders.rider'],
        order: { createdAt: 'DESC' },
      });
    }
  }

  async updateDriverLocation(
    id: string,
    lat: number,
    lng: number,
  ): Promise<void> {
    const event = this.eventRepo.create({
      tripId: id,
      eventType: 'DRIVER_LOCATION',
      metadata: { lat, lng },
    });
    await this.eventRepo.save(event);
  }

  /**
   * Update Trip Status with State Machine validation (Module 1.8)
   */
  async updateTripStatus(tripId: string, newStatus: TripStatus): Promise<TripEntity> {
    const trip = await this.tripRepo.findOne({ where: { id: tripId } });
    if (!trip) throw new NotFoundException('Trip not found');

    const oldStatus = trip.status;
    this.validateTransition(oldStatus, newStatus);

    trip.status = newStatus;

    // Side effects based on state
    if (newStatus === TripStatus.ASSIGNED) {
      trip.assignedAt = new Date();
    } else if (newStatus === TripStatus.IN_PROGRESS) {
      trip.startAt = new Date();
    } else if (newStatus === TripStatus.COMPLETED || newStatus === TripStatus.CANCELLED) {
      trip.endAt = new Date();
    }

    const savedTrip = await this.tripRepo.save(trip);

    // On completion: calculate and persist final fares per rider
    if (newStatus === TripStatus.COMPLETED && trip.startAt) {
      const durationSeconds = (trip.endAt!.getTime() - trip.startAt.getTime()) / 1000;
      const riders = await this.tripRiderRepo.find({ where: { tripId }, relations: ['trip'] });
      if (riders.length > 0) {
        const vehicleType = (trip.vehicleType as any) ?? 'AUTO';
        const rideType = ride_type_from_count(riders.length);
        const distanceMeters = trip.distanceMeters ?? 5_000;
        for (const rider of riders) {
          const fare = this.fareService.calculate(
            vehicleType,
            rideType,
            distanceMeters,
            durationSeconds,
            riders.length,
          );
          rider.fareShare = fare.perRiderFare;
          await this.tripRiderRepo.save(rider);

          // Auto-charge rider wallet; fall back to cash (no balance deducted) if insufficient
          try {
            await this.paymentsService.processTripPayment(rider.riderUserId, {
              tripId,
              method: PaymentMethod.WALLET,
            });
          } catch {
            try {
              await this.paymentsService.processTripPayment(rider.riderUserId, {
                tripId,
                method: PaymentMethod.CASH,
              });
            } catch (inner) {
              this.logger.warn(`Auto-payment failed for rider ${rider.riderUserId} on trip ${tripId}: ${inner}`);
            }
          }
        }
      }
    }

    // Module 1.9: Real-Time Communication
    this.locationGateway.server.to(`trip:${tripId}`).emit('trip_status_changed', {
      tripId,
      oldStatus,
      newStatus,
    });

    return savedTrip;
  }

  /**
   * Validate state transition rules (Module 1.8)
   */
  private validateTransition(current: TripStatus, target: TripStatus) {
    const valid: Record<TripStatus, TripStatus[]> = {
      [TripStatus.REQUESTED]: [TripStatus.ASSIGNED, TripStatus.CANCELLED],
      [TripStatus.ASSIGNED]: [TripStatus.ARRIVING, TripStatus.CANCELLED],
      [TripStatus.ARRIVING]: [TripStatus.IN_PROGRESS, TripStatus.CANCELLED],
      [TripStatus.IN_PROGRESS]: [TripStatus.COMPLETED, TripStatus.CANCELLED],
      [TripStatus.COMPLETED]: [],
      [TripStatus.CANCELLED]: [],
    };

    if (!valid[current].includes(target)) {
      throw new BadRequestException(`Invalid trip status transition: ${current} -> ${target}`);
    }
  }

  /**
   * Helper to fetch, validate, and assign driver inside a transaction or lock
   */
  private async assignDriver(tripId: string, driverId: string): Promise<TripEntity> {
    const trip = await this.tripRepo.findOne({
      where: { id: tripId },
      relations: ['driver', 'tripRiders'],
    });

    if (!trip) throw new NotFoundException('Trip not found');

    if (trip.status !== TripStatus.REQUESTED) {
      throw new BadRequestException(`Trip is no longer available (Status: ${trip.status})`);
    }

    if (trip.driver?.id) {
      throw new BadRequestException('Trip has already been assigned to a driver');
    }

    // Update Trip
    trip.driver = { id: driverId } as any;
    trip.status = TripStatus.ASSIGNED;
    trip.assignedAt = new Date();

    return this.tripRepo.save(trip);
  }

  /**
   * Driver accepts a trip request (Module 1.5 - Race condition locked)
   */
  async acceptTrip(tripId: string, driverId: string): Promise<TripEntity> {
    const lockKey = `lock:trip_accept:${tripId}`;
    const lockTtl = 5000; // 5 seconds lock

    // 1. Acquire Redis Lock (Mutex) - prevents race condition
    const acquiredLock = await this.redisClient.set(lockKey, driverId, 'PX', lockTtl, 'NX');
    if (!acquiredLock) {
      throw new BadRequestException('Another driver is already accepting this trip');
    }

    try {
      const trip = await this.assignDriver(tripId, driverId);

      // Notify users
      this.locationGateway.server.to(`trip:${tripId}`).emit('trip_status_changed', {
        tripId,
        oldStatus: TripStatus.REQUESTED,
        newStatus: TripStatus.ASSIGNED,
        driverId,
        driver: {
          id: driverId,
          name: trip.driver?.fullName || 'Driver',
          phone: trip.driver?.phone || '',
          vehicleNumber: 'TN 12 A 1234', // In production, fetch from driver's vehicle entity
          vehicleModel: 'Sedan',
          vehicleColor: 'White',
          rating: 4.8,
        }
      });

      return trip;
    } finally {
      // 2. Release Lock safely (only if we own it)
      const currentLockHolder = await this.redisClient.get(lockKey);
      if (currentLockHolder === driverId) {
        await this.redisClient.del(lockKey);
      }
    }
  }

  /**
   * GET /api/v1/trips/:id/fare
   * Returns the fare breakdown for each rider after trip completes.
   */
  async getTripFare(tripId: string) {
    const trip = await this.tripRepo.findOne({ where: { id: tripId } });
    if (!trip) throw new NotFoundException('Trip not found');

    const riders = await this.tripRiderRepo.find({
      where: { tripId },
      relations: ['rider'],
    });

    return {
      tripId,
      status: trip.status,
      riders: riders.map((r) => ({
        riderId: r.riderUserId,
        riderName: (r.rider as any)?.fullName ?? null,
        fareShare: r.fareShare,
        currencyCode: 'INR',
      })),
    };
  }

  async submitTripRating(
    tripId: string,
    riderUserId: string,
    dto: { rating: number; feedback?: string; tags?: string[] },
  ) {
    const trip = await this.tripRepo.findOne({ where: { id: tripId } });
    if (!trip) throw new NotFoundException('Trip not found');
    if (trip.status !== TripStatus.COMPLETED) {
      throw new BadRequestException('Trip rating is allowed only after completion');
    }
    if (!trip.driverUserId) {
      throw new BadRequestException('Trip has no assigned driver');
    }

    const riderOnTrip = await this.tripRiderRepo.findOne({
      where: { tripId, riderUserId },
    });
    if (!riderOnTrip) {
      throw new BadRequestException('Rider is not associated with this trip');
    }

    const priorRatings = await this.eventRepo.find({
      where: { tripId, eventType: 'RIDER_RATING' },
      order: { createdAt: 'ASC' },
    });

    const alreadyRated = priorRatings.some((event) => {
      const metadata = event.metadata;
      if (metadata == null) return false;
      const ratedBy = metadata['riderUserId'];
      return typeof ratedBy === 'string' && ratedBy === riderUserId;
    });

    if (alreadyRated) {
      throw new BadRequestException('Rating already submitted for this trip');
    }

    const driverProfile = await this.driverProfileRepo.findOne({
      where: { userId: trip.driverUserId },
    });

    if (!driverProfile) {
      throw new NotFoundException('Driver profile not found');
    }

    const currentAvg = Number(driverProfile.ratingAvg || 0);
    const currentCount = Number(driverProfile.ratingCount || 0);
    const newCount = currentCount + 1;
    const newAvg = ((currentAvg * currentCount) + dto.rating) / newCount;

    driverProfile.ratingCount = newCount;
    driverProfile.ratingAvg = Number(newAvg.toFixed(2));
    await this.driverProfileRepo.save(driverProfile);

    const ratingEvent = this.eventRepo.create({
      tripId,
      eventType: 'RIDER_RATING',
      metadata: {
        riderUserId,
        driverUserId: trip.driverUserId,
        rating: dto.rating,
        feedback: dto.feedback ?? null,
        tags: dto.tags ?? [],
      },
    });
    await this.eventRepo.save(ratingEvent);

    return {
      success: true,
      rating: dto.rating,
      driverRatingAvg: driverProfile.ratingAvg,
      driverRatingCount: driverProfile.ratingCount,
    };
  }
}
