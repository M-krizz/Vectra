import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RideRequestEntity, RideRequestStatus, RideType } from './ride-request.entity';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { UserEntity } from '../users/user.entity';

@Injectable()
export class RideRequestsService {
    constructor(
        @InjectRepository(RideRequestEntity)
        private readonly rideRequestRepo: Repository<RideRequestEntity>,
    ) { }

    async createRequest(user: UserEntity, dto: CreateRideRequestDto): Promise<RideRequestEntity> {
        const rideRequest = this.rideRequestRepo.create({
            rider: user,
            pickupPoint: {
                type: 'Point',
                coordinates: [dto.pickupLng, dto.pickupLat],
            },
            dropPoint: {
                type: 'Point',
                coordinates: [dto.dropLng, dto.dropLat],
            },
            pickupAddress: dto.pickupAddress,
            dropAddress: dto.dropAddress,
            rideType: dto.rideType || RideType.SOLO,
            status: RideRequestStatus.REQUESTED,
        });

        return await this.rideRequestRepo.save(rideRequest);
    }

    async findNearbyRequests(lat: number, lng: number, radiusKm: number = 5): Promise<RideRequestEntity[]> {
        // ST_DWithin takes geometry, geometry, distance_in_meters (if geography) or degrees (if geometry)
        // Since we use geography type in entity (likely), the distance is in meters.

        return this.rideRequestRepo
            .createQueryBuilder('request')
            .where('request.status = :status', { status: RideRequestStatus.REQUESTED })
            .andWhere(
                `ST_DWithin(request.pickup_point, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326), :radius)`
            )
            .setParameters({
                lng,
                lat,
                radius: radiusKm * 1000, // convert km to meters
            })
            .getMany();
    }
}
