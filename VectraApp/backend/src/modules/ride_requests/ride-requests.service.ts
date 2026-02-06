import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RideRequestEntity, RideRequestStatus } from './ride-request.entity';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { GeoPoint } from '../../common/types/geo-point.type';

@Injectable()
export class RideRequestsService {
  private readonly logger = new Logger(RideRequestsService.name);

  constructor(
    @InjectRepository(RideRequestEntity)
    private readonly rideRequestsRepo: Repository<RideRequestEntity>,
  ) {}

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
      status: RideRequestStatus.REQUESTED,
    });

    return this.rideRequestsRepo.save(rideRequest);
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
