import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RideRequestEntity } from './ride-request.entity';
import { RideRequestStatus, VehicleType } from './ride-request.enums';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { GeoPoint } from '../../common/types/geo-point.type';
import { SocketGateway } from '../../realtime/socket.gateway';
import { DataSource } from 'typeorm';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripRiderEntity, TripRiderStatus } from '../trips/trip-rider.entity';
import { UserEntity } from '../Authentication/users/user.entity';

@Injectable()
export class RideRequestsService {
  private readonly logger = new Logger(RideRequestsService.name);

  constructor(
    @InjectRepository(RideRequestEntity)
    private readonly rideRequestsRepo: Repository<RideRequestEntity>,
    private readonly socketGateway: SocketGateway,
    private readonly dataSource: DataSource,
  ) { }

  async createRequest(
    userId: string,
    dto: CreateRideRequestDto,
  ): Promise<RideRequestEntity> {
    const rideRequest = this.rideRequestsRepo.create({
      riderUserId: userId,
      pickupPoint: dto.pickupPoint as GeoPoint,
      dropPoint: dto.dropPoint as GeoPoint,
      pickupAddress: dto.pickupAddress,
      dropAddress: dto.dropAddress,
      rideType: dto.rideType,
      vehicleType: dto.vehicleType || VehicleType.AUTO, // Default if not provided
      status: RideRequestStatus.REQUESTED,
    });

    const saved = await this.rideRequestsRepo.save(rideRequest);
    this.socketGateway.emitTripStatus(saved.id, 'REQUESTED', { rideRequest: saved });
    return saved;
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
    this.socketGateway.emitTripStatus(id, 'CANCELLED', { reason: 'Cancelled by rider' });
  }

  async acceptSoloRideRequest(rideRequestId: string, driverUserId: string) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Lock the Ride Request to prevent double-booking
      const request = await queryRunner.manager
        .createQueryBuilder(RideRequestEntity, 'request')
        .setLock('pessimistic_write')
        .where('request.id = :id', { id: rideRequestId })
        .getOne();

      if (!request || request.status !== RideRequestStatus.REQUESTED) {
        throw new Error('Ride request is no longer available');
      }

      // 2. Fetch the rider to include their name in the response
      const rider = await queryRunner.manager.findOne(UserEntity, { where: { id: request.riderUserId } });

      // 3. Mark request as assigned
      request.status = RideRequestStatus.ACCEPTED; // Or however Vectra models it
      await queryRunner.manager.save(request);

      // 4. Create the Trip
      const trip = queryRunner.manager.create(TripEntity, {
        driverUserId,
        status: TripStatus.ASSIGNED,
        assignedAt: new Date(),
      });
      const savedTrip = await queryRunner.manager.save(trip);

      // 5. Link the Rider to the Trip
      const tripRider = queryRunner.manager.create(TripRiderEntity, {
        tripId: savedTrip.id,
        riderUserId: request.riderUserId,
        pickupPoint: request.pickupPoint,
        dropPoint: request.dropPoint,
        status: TripRiderStatus.JOINED,
      });
      await queryRunner.manager.save(tripRider);

      await queryRunner.commitTransaction();

      // Emit event to Rider using tripId or rideRequestId. Usually Rider app expects rideId
      this.socketGateway.emitTripStatus(request.id, 'ACCEPTED', { tripId: savedTrip.id, driverId: driverUserId });

      // Build driver-friendly response
      return {
        id: savedTrip.id,
        riderId: request.riderUserId,
        riderName: rider?.fullName || 'Rider',
        riderPhone: rider?.phone || null,
        riderRating: 5.0, // Mock rating
        pickupLocation: {
          lat: request.pickupPoint.coordinates[1],
          lng: request.pickupPoint.coordinates[0],
        },
        pickupAddress: request.pickupAddress,
        dropoffLocation: {
          lat: request.dropPoint.coordinates[1],
          lng: request.dropPoint.coordinates[0],
        },
        dropoffAddress: request.dropAddress,
        fare: 250.0, // Mock fare calculation
        distance: 5.0, // Mock distance
        status: 'assigned', // Dart enum value 'assigned'
        vehicleType: request.vehicleType,
      };

    } catch (err) {
      await queryRunner.rollbackTransaction();
      this.logger.error('Failed to accept ride', err);
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}
