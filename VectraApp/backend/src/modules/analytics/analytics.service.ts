import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { UserEntity } from '../Authentication/users/user.entity';

@Injectable()
export class AnalyticsService {
    constructor(
        @InjectRepository(TripEntity)
        private readonly tripRepo: Repository<TripEntity>,
        @InjectRepository(UserEntity)
        private readonly userRepo: Repository<UserEntity>,
    ) { }

    async getDashboardStats() {
        const totalUsers = await this.userRepo.count();
        const totalTrips = await this.tripRepo.count();
        const completedTrips = await this.tripRepo.count({
            where: { status: TripStatus.COMPLETED },
        });

        // Calculate simple stats
        const totalRevenue = completedTrips * 12.5; // Mock fixed avg revenue

        return {
            totalUsers,
            totalTrips,
            completedTrips,
            totalRevenue,
        };
    }

    async getRevenueTrend() {
        // Return dummy 7-day trend for the dashboard component
        return [
            { name: 'Mon', revenue: 2400 },
            { name: 'Tue', revenue: 4130 },
            { name: 'Wed', revenue: 5200 },
            { name: 'Thu', revenue: 4800 },
            { name: 'Fri', revenue: 7900 },
            { name: 'Sat', revenue: 9500 },
            { name: 'Sun', revenue: 8100 },
        ];
    }

    async getTripTrend() {
        return [
            { name: 'Mon', trips: 145 },
            { name: 'Tue', trips: 230 },
            { name: 'Wed', trips: 280 },
            { name: 'Thu', trips: 260 },
            { name: 'Fri', trips: 390 },
            { name: 'Sat', trips: 450 },
            { name: 'Sun', trips: 380 },
        ];
    }
}
