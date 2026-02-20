import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { MatchingService } from './matching.service';

@Injectable()
export class MatchingManager {
    private readonly logger = new Logger(MatchingManager.name);

    constructor(
        @InjectRepository(TripEntity)
        private readonly tripRepo: Repository<TripEntity>,
        private readonly matchingService: MatchingService,
    ) { }

    /**
     * Main Matching Loop: Runs every 5 seconds (Module 1.5)
     * Scans for REQUESTED trips and attempts to match them.
     */
    @Cron('*/5 * * * * *') // Every 5 seconds
    async handleMatchingLoop() {
        const pendingTrips = await this.tripRepo.find({
            where: { status: TripStatus.REQUESTED },
            relations: ['tripRiders']
        });

        if (pendingTrips.length === 0) return;

        this.logger.debug(`Processing matching for ${pendingTrips.length} trips`);

        for (const trip of pendingTrips) {
            try {
                const drivers = await this.matchingService.findNearbyDrivers(trip.id);
                if (drivers.length > 0) {
                    await this.matchingService.offerTripToDrivers(trip.id, drivers);
                } else {
                    this.logger.debug(`No drivers found for trip ${trip.id} in radius`);
                }
            } catch (err) {
                this.logger.error(`Error matching trip ${trip.id}`, err);
            }
        }
    }
}
