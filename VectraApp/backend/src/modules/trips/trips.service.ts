import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity, TripStatus } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { LocationGateway } from '../location/location.gateway';

@Injectable()
export class TripsService {
  private readonly logger = new Logger(TripsService.name);

  constructor(
    @InjectRepository(TripEntity)
    private readonly tripRepo: Repository<TripEntity>,
    @InjectRepository(TripEventEntity)
    private readonly eventRepo: Repository<TripEventEntity>,
    private readonly locationGateway: LocationGateway,
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
}
