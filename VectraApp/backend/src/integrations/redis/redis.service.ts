import { Injectable, Inject } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS } from './redis.module';

@Injectable()
export class RedisService {
    constructor(@Inject(REDIS) private readonly redis: Redis) { }

    /**
     * Update driver's real-time location using geospatial index
     * Key: 'drivers:locations'
     * Member: driverId
     */
    /**
     * Update driver's real-time location using geospatial index
     * Key: 'drivers:locations' (GEO)
     * Key: 'drivers:heartbeat' (ZSET) - for tracking staleness
     */
    async updateDriverLocation(driverId: string, lat: number, lng: number): Promise<void> {
        const pipeline = this.redis.pipeline();
        pipeline.geoadd('drivers:locations', lng, lat, driverId);
        pipeline.zadd('drivers:heartbeat', Date.now(), driverId);
        await pipeline.exec();
    }

    /**
     * Get drivers who haven't updated location since the threshold timestamp
     */
    async getInactiveDrivers(thresholdTimestamp: number): Promise<string[]> {
        return await this.redis.zrangebyscore('drivers:heartbeat', 0, thresholdTimestamp);
    }

    async removeDriverHeartbeat(driverIds: string[]): Promise<void> {
        if (driverIds.length === 0) return;
        await this.redis.zrem('drivers:heartbeat', ...driverIds);
    }

    /**
     * Find drivers within radius
     * @param lat Latitude
     * @param lng Longitude
     * @param radiusKm Radius in kilometers
     * @returns Array of driver IDs and their details
     */
    async getNearbyDrivers(lat: number, lng: number, radiusKm: number): Promise<string[]> {
        // geo search is available in newer redis versions, or georadius in older
        // ioredis supports these. 
        // using geosearch which is preferred in Redis 6.2+
        const result = await this.redis.geosearch(
            'drivers:locations',
            'FROMLONLAT',
            lng,
            lat,
            'BYRADIUS',
            radiusKm,
            'km',
            'ASC'
        );
        return result; // returns string[] of members (driverIds)
    }

    /**
     * Get position of specific driver
     */
    async getDriverPosition(driverId: string): Promise<[number, number] | null> {
        const result = await this.redis.geopos('drivers:locations', driverId);
        if (result && result.length > 0 && result[0]) {
            const [lng, lat] = result[0];
            return [parseFloat(lat), parseFloat(lng)];
        }
        return null;
    }

    /**
     * Remove driver from geospatial index (e.g. when going offline)
     */
    async removeDriverLocation(driverId: string): Promise<void> {
        await this.redis.zrem('drivers:locations', driverId);
    }

    public getRedisClient(): Redis {
        return this.redis;
    }
}
