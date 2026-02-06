import { Injectable } from '@nestjs/common';
import { RedisService } from '../../integrations/redis/redis.service';
import { RideRequestsService } from '../ride_requests/ride-requests.service';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';

@Injectable()
export class DriversService {
    constructor(
        private readonly redisService: RedisService,
        private readonly rideRequestsService: RideRequestsService,
    ) { }

    async getNearbyRequests(driverId: string, lat: number, lng: number): Promise<RideRequestEntity[]> {
        // 1. Update driver location in Redis (implicitly treating this fetch as a heartbeat/location update)
        // Alternatively, client should call updateLocation separately.
        // Let's keep it separate for SRP, but querying requires location.

        // 2. Query PostGIS for requests
        const radiusKm = 5; // Configurable
        return await this.rideRequestsService.findNearbyRequests(lat, lng, radiusKm);
    }

    async updateLocation(driverId: string, lat: number, lng: number): Promise<void> {
        await this.redisService.updateDriverLocation(driverId, lat, lng);
        // Also could trigger socket checks here if we want to push "driver nearby" alerts to riders
    }
}
