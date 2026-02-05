import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';

@Injectable()
export class TripsService {
  constructor(
    @InjectRepository(TripEntity)
    private readonly tripRepo: Repository<TripEntity>,
    @InjectRepository(TripEventEntity)
    private readonly eventRepo: Repository<TripEventEntity>,
  ) {}

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
}
