import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RideRequest, RideStatus } from './entities/ride-request.entity';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { User } from '../users/user.entity';

@Injectable()
export class RidesService {
    constructor(
        @InjectRepository(RideRequest)
        private rideRequestRepo: Repository<RideRequest>,
        @InjectRepository(User)
        private userRepo: Repository<User>,
    ) { }

    async createRequest(userId: string, dto: CreateRideRequestDto) {
        const rider = await this.userRepo.findOne({ where: { id: userId } });
        if (!rider) throw new NotFoundException('Rider not found');

        const rideRequest = this.rideRequestRepo.create({
            rider,
            pickupLocation: `POINT(${dto.pickupLng} ${dto.pickupLat})`,
            dropoffLocation: `POINT(${dto.dropoffLng} ${dto.dropoffLat})`,
            pickupAddress: dto.pickupAddress,
            dropoffAddress: dto.dropoffAddress,
            status: RideStatus.PENDING,
        });

        // Simple fare calculation: $2 base + $1.5 per km (rough estimate)
        // In a real app, use Google Matrix API or similar
        rideRequest.distance = 5.0; // Placeholder
        rideRequest.fare = 2.0 + (rideRequest.distance * 1.5);

        return this.rideRequestRepo.save(rideRequest);
    }

    async findNearbyRequests(lat: number, lng: number, radiusInMeters: number = 5000) {
        return this.rideRequestRepo
            .createQueryBuilder('ride')
            .leftJoinAndSelect('ride.rider', 'rider')
            .where(
                'ST_DWithin(ride.pickupLocation, ST_MakePoint(:lng, :lat)::geography, :radius)',
                { lng, lat, radius: radiusInMeters }
            )
            .andWhere('ride.status = :status', { status: RideStatus.PENDING })
            .getMany();
    }

    async getRideDetails(rideId: string) {
        const ride = await this.rideRequestRepo.findOne({
            where: { id: rideId },
            relations: ['rider', 'driver'],
        });
        if (!ride) throw new NotFoundException('Ride request not found');
        return ride;
    }
}
