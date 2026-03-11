import { Injectable, Logger, Inject } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriverProfileEntity, DriverStatus } from '../Authentication/drivers/driver-profile.entity';
import { VehicleEntity } from '../Authentication/drivers/vehicle.entity';
import { TripEntity } from '../trips/trip.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { VehicleType } from '../ride_requests/ride-request.enums';
import { LocationGateway } from '../location/location.gateway';
import Redis from 'ioredis';
import { REDIS } from '../../integrations/redis/redis.module';
import { getLatitude, getLongitude } from '../../common/types/geo-point.type';
import { MapsService } from '../maps/maps.service';

// ─── Haversine helper (fallback when Google Maps is unavailable) ──────────────
function haversineMeters(
  lat1: number, lng1: number,
  lat2: number, lng2: number,
): number {
  const R = 6_371_000; // earth radius in metres
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
export class MatchingService {
  private readonly logger = new Logger(MatchingService.name);

  constructor(
    @InjectRepository(DriverProfileEntity)
    private readonly driverProfileRepo: Repository<DriverProfileEntity>,
    @InjectRepository(VehicleEntity)
    private readonly vehicleRepo: Repository<VehicleEntity>,
    @InjectRepository(TripEntity)
    private readonly tripRepo: Repository<TripEntity>,
    @InjectRepository(RideRequestEntity)
    private readonly rideRequestRepo: Repository<RideRequestEntity>,
    @Inject(REDIS) private readonly redisClient: Redis,
    private readonly locationGateway: LocationGateway,
    private readonly mapsService: MapsService,
  ) { }

  /**
   * Find and rank nearby available drivers by ETA + Rating.
   * Accepts VERIFIED drivers OR drivers that are at least UNDER_REVIEW
   * (soft-launch / dev mode — tighten to VERIFIED in production).
   */
  async findNearbyDrivers(tripId: string, radiusKm = 5): Promise<string[]> {
    const trip = await this.tripRepo.findOne({
      where: { id: tripId },
      relations: ['tripRiders'],
    });
    if (!trip || trip.tripRiders.length === 0) return [];

    const pickup = trip.tripRiders[0].pickupPoint;
    const lng = getLongitude(pickup);
    const lat = getLatitude(pickup);

    // 1. Nearby drivers from Redis geo-index ─────────────────────────────────
    const nearbyRaw: any[] = (await this.redisClient.georadius(
      'drivers:geo',
      lng,
      lat,
      radiusKm,
      'km',
      'WITHCOORD',
    )) as any[];

    if (nearbyRaw.length === 0) return [];

    const driverIds = nearbyRaw.map((d) => d[0]);
    const driverLocations = new Map<string, { lat: number; lng: number }>();
    nearbyRaw.forEach((d) => {
      driverLocations.set(d[0], {
        lat: parseFloat(d[1][1]),
        lng: parseFloat(d[1][0]),
      });
    });

    // 2. DB filter: online + acceptable verification status ───────────────────
    const ACCEPTED_STATUSES = [DriverStatus.VERIFIED, DriverStatus.UNDER_REVIEW];
    const verifiedDrivers = await this.driverProfileRepo
      .createQueryBuilder('profile')
      .where('profile.userId IN (:...ids)', { ids: driverIds })
      .andWhere('profile.onlineStatus = :online', { online: true })
      .andWhere('profile.status IN (:...statuses)', { statuses: ACCEPTED_STATUSES })
      .select(['profile.userId', 'profile.ratingAvg'])
      .getMany();

    if (verifiedDrivers.length === 0) return [];

    // 3. Vehicle type filter ──────────────────────────────────────────────────
    // Only offer the trip to drivers whose active vehicle matches the required type.
    const requiredVehicleType = trip.vehicleType as VehicleType | null;
    let eligibleDriverIds: string[] = verifiedDrivers.map((d) => d.userId);

    if (requiredVehicleType) {
      const vehicles = await this.vehicleRepo
        .createQueryBuilder('v')
        .where('v.driverUserId IN (:...ids)', { ids: eligibleDriverIds })
        .andWhere('v.vehicleType = :vt', { vt: requiredVehicleType })
        .andWhere('v.isActive = :active', { active: true })
        .select(['v.driverUserId'])
        .getMany();

      const vehicleOwnerIds = new Set(vehicles.map((v) => v.driverUserId));
      eligibleDriverIds = eligibleDriverIds.filter((id) => vehicleOwnerIds.has(id));
    }

    if (eligibleDriverIds.length === 0) return [];

    const eligibleDrivers = verifiedDrivers.filter((d) =>
      eligibleDriverIds.includes(d.userId),
    );

    // 4. Score each driver: lower = better ───────────────────────────────────
    const scoredDrivers = await Promise.all(
      eligibleDrivers.map(async (driver) => {
        const loc = driverLocations.get(driver.userId);
        let etaSeconds = 600; // default 10 min

        if (loc) {
          try {
            const etaRes = await this.mapsService.getEtaAndDistance(
              { type: 'Point', coordinates: [loc.lng, loc.lat] },
              pickup,
            );
            etaSeconds = etaRes.durationSeconds;
          } catch {
            // Fallback to haversine-based ETA (assume 25 km/h avg speed)
            const distM = haversineMeters(loc.lat, loc.lng, lat, lng);
            etaSeconds = Math.round((distM / 25_000) * 3600);
          }
        }

        const rating = Number(driver.ratingAvg || 4.0);
        const ratingBonus = Math.max(0, (rating - 3.0) * 50);
        const score = Math.max(0, etaSeconds - ratingBonus);
        return { id: driver.userId, score, etaSeconds };
      }),
    );

    scoredDrivers.sort((a, b) => a.score - b.score);
    this.logger.debug(`Found ${scoredDrivers.length} ranked drivers for trip ${tripId}`);
    return scoredDrivers.map((d) => d.id);
  }

  /**
   * Broadcast ride offer to a ranked list of drivers via WebSocket.
   * Includes enriched payload so the Flutter app can render it without extra calls.
   */
  async offerTripToDrivers(tripId: string, driverIds: string[]) {
    const trip = await this.tripRepo.findOne({
      where: { id: tripId },
      relations: ['tripRiders', 'tripRiders.rider'],
    });

    if (!trip || trip.tripRiders.length === 0) {
      this.logger.warn(`Cannot offer trip ${tripId}: not found or no riders`);
      return;
    }

    const firstRider = trip.tripRiders[0];
    const rider = firstRider.rider;

    // Fetch pickup/drop addresses from the matching ride request
    const rideRequest = await this.rideRequestRepo.findOne({
      where: { riderUserId: firstRider.riderUserId },
      order: { requestedAt: 'DESC' },
      select: ['pickupAddress', 'dropAddress', 'vehicleType', 'rideType'],
    });

    // Estimate trip distance ─────────────────────────────────────────────────
    let distanceMeters = 0;
    try {
      const routeInfo = await this.mapsService.getEtaAndDistance(
        firstRider.pickupPoint,
        firstRider.dropPoint,
      );
      distanceMeters = routeInfo.distanceMeters;
    } catch {
      // Haversine fallback
      const pLat = getLatitude(firstRider.pickupPoint);
      const pLng = getLongitude(firstRider.pickupPoint);
      const dLat = getLatitude(firstRider.dropPoint);
      const dLng = getLongitude(firstRider.dropPoint);
      distanceMeters = Math.round(haversineMeters(pLat, pLng, dLat, dLng));
    }

    const payload = {
      tripId: trip.id,
      status: trip.status,
      rideType: rideRequest?.rideType ?? 'SOLO',
      vehicleType: rideRequest?.vehicleType ?? 'AUTO',
      riderName: (rider as any)?.fullName ?? 'Rider',
      riderPhone: (rider as any)?.phone ?? null,
      riderId: firstRider.riderUserId,
      pickupLocation: firstRider.pickupPoint,
      dropoffLocation: firstRider.dropPoint,
      pickupAddress: rideRequest?.pickupAddress ?? '',
      dropoffAddress: rideRequest?.dropAddress ?? '',
      fare: Number(firstRider.fareShare ?? 0),
      distance: distanceMeters,
      riderCount: trip.tripRiders.length,
      createdAt: trip.createdAt?.toISOString(),
    };

    for (const driverId of driverIds) {
      this.locationGateway.server
        .to(`user:${driverId}`)
        .emit('ride_offered', payload);
      this.logger.log(`Offered trip ${tripId} to driver ${driverId}`);
    }
  }
}

