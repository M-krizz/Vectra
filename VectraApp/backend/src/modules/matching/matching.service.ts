import { Injectable, Logger, Inject } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriverProfileEntity, DriverStatus } from '../Authentication/drivers/driver-profile.entity';
import { TripEntity } from '../trips/trip.entity';
import { LocationGateway } from '../location/location.gateway';
import Redis from 'ioredis';
import { REDIS } from '../../integrations/redis/redis.module';
import { getLatitude, getLongitude } from '../../common/types/geo-point.type';

@Injectable()
export class MatchingService {
    private readonly logger = new Logger(MatchingService.name);

    constructor(
        @InjectRepository(DriverProfileEntity)
        private readonly driverProfileRepo: Repository<DriverProfileEntity>,
        @InjectRepository(TripEntity)
        private readonly tripRepo: Repository<TripEntity>,
        @Inject(REDIS) private readonly redisClient: Redis,
        private readonly locationGateway: LocationGateway,
    ) { }

    /**
     * Find nearby available drivers using Redis Geospatial Index (Module 1.5)
     */
    async findNearbyDrivers(tripId: string, radiusKm: number = 5): Promise<string[]> {
        const trip = await this.tripRepo.findOne({
            where: { id: tripId },
            relations: ['tripRiders'],
        });
        if (!trip || trip.tripRiders.length === 0) return [];

        const pickup = trip.tripRiders[0].pickupPoint;
        const lng = getLongitude(pickup);
        const lat = getLatitude(pickup);

        // Filter available drivers in radius from Redis
        const driverIds: string[] = (await this.redisClient.georadius(
            'drivers:geo',
            lng,
            lat,
            radiusKm,
            'km',
        )) as string[];

        if (driverIds.length === 0) return [];

        // Further filter by onlineStatus and DriverStatus.VERIFIED in DB
        const verifiedDrivers = await this.driverProfileRepo.createQueryBuilder('profile')
            .where('profile.userId IN (:...ids)', { ids: driverIds })
            .andWhere('profile.onlineStatus = :online', { online: true })
            .andWhere('profile.status = :status', { status: DriverStatus.VERIFIED })
            .select(['profile.userId'])
            .getMany();

        return verifiedDrivers.map(d => d.userId);
    }

    /**
     * Send ride offer to drivers via WebSocket (Module 1.5)
     */
    async offerTripToDrivers(tripId: string, driverIds: string[]) {
        for (const driverId of driverIds) {
            this.locationGateway.server.to(`user:${driverId}`).emit('ride_offered', {
                tripId,
            });
            this.logger.log(`Offered trip ${tripId} to driver ${driverId}`);
        }
    }
}
