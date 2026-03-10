import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripEventEntity } from '../trips/trip-event.entity';
import { TripRiderEntity, TripRiderStatus } from '../trips/trip-rider.entity';
import { LocationGateway } from '../location/location.gateway';
import { PaymentsService } from '../payments/payments.service';
import { PaymentMethod } from '../payments/entities/payment.entity';
import { CancelTripDto } from './dto/cancel.dto';
import Redis from 'ioredis';
import { Inject } from '@nestjs/common';
import { REDIS } from '../../integrations/redis/redis.module';

@Injectable()
export class CancellationsService {
    private readonly logger = new Logger(CancellationsService.name);

    // Settings for cancellation logic
    private readonly LATE_CANCEL_FEE = 20.00; // INR
    private readonly GRACE_PERIOD_MS = 3 * 60 * 1000; // 3 minutes

    constructor(
        @InjectRepository(TripEntity)
        private readonly tripRepo: Repository<TripEntity>,
        @InjectRepository(TripEventEntity)
        private readonly eventRepo: Repository<TripEventEntity>,
        @InjectRepository(TripRiderEntity)
        private readonly tripRiderRepo: Repository<TripRiderEntity>,
        private readonly locationGateway: LocationGateway,
        private readonly paymentsService: PaymentsService,
        @Inject(REDIS) private readonly redisClient: Redis,
    ) { }

    /**
     * Rider cancels their request/trip
     */
    async cancelByRider(userId: string, dto: CancelTripDto) {
        const tripRider = await this.tripRiderRepo.findOne({
            where: { tripId: dto.tripId, riderUserId: userId },
            relations: ['trip'],
        });

        if (!tripRider) throw new NotFoundException('Trip or rider not found');
        const trip = tripRider.trip;

        if ([TripStatus.COMPLETED, TripStatus.CANCELLED].includes(trip.status)) {
            throw new BadRequestException('Trip is already completed or cancelled');
        }

        // 1. Calculate possible late cancellation fee
        let feeCharged = 0;
        if (trip.status === TripStatus.ASSIGNED || trip.status === TripStatus.ARRIVING) {
            const msSinceAssigned = new Date().getTime() - (trip.assignedAt?.getTime() || 0);

            // If driver was assigned more than 3 minutes ago, charge a fee
            if (msSinceAssigned > this.GRACE_PERIOD_MS) {
                feeCharged = this.LATE_CANCEL_FEE;
                // In a real app, this would use the PaymentsService to deduct from wallet or add to next trip bill
                this.logger.log(`Charging late cancel fee ${feeCharged} INR to user ${userId}`);
            }
        }

        // 2. Update statuses
        tripRider.status = TripRiderStatus.CANCELLED;
        await this.tripRiderRepo.save(tripRider);

        // If this was a solo trip or the last rider in a pool, cancel the whole trip
        const activeRiders = await this.tripRiderRepo.count({
            where: { tripId: trip.id, status: TripRiderStatus.JOINED },
        });

        if (activeRiders === 0) {
            trip.status = TripStatus.CANCELLED;
            trip.endAt = new Date();
            await this.tripRepo.save(trip);

            // Free the driver
            if (trip.driver?.id) {
                await this.redisClient.del(`trip:driver:${trip.id}`);
            }
        }

        // 3. Log event
        const event = this.eventRepo.create({
            tripId: trip.id,
            eventType: 'TRIP_CANCELLED',
            metadata: { expectedFee: feeCharged, reason: dto.reason, cancelledBy: userId, role: 'RIDER' },
        });
        await this.eventRepo.save(event);

        // 4. Notify participants
        this.locationGateway.server.to(`trip:${trip.id}`).emit('trip_status_changed', {
            tripId: trip.id,
            oldStatus: trip.status,
            newStatus: TripStatus.CANCELLED,
            reason: dto.reason,
            cancelledBy: userId,
        });

        return {
            success: true,
            message: 'Trip cancelled successfully',
            feeCharged,
        };
    }

    /**
     * Driver cancels the trip (e.g. Rider config, or no show)
     */
    async cancelByDriver(driverId: string, dto: CancelTripDto) {
        const trip = await this.tripRepo.findOne({
            where: { id: dto.tripId },
        });

        if (!trip) throw new NotFoundException('Trip not found');

        // Using string matching as driver might not be relations populated
        if (trip.driver?.id !== driverId) {
            throw new BadRequestException('You are not assigned to this trip');
        }

        if ([TripStatus.COMPLETED, TripStatus.CANCELLED].includes(trip.status)) {
            throw new BadRequestException('Trip is already completed or cancelled');
        }

        // Update Trip
        trip.status = TripStatus.CANCELLED;
        trip.endAt = new Date();
        await this.tripRepo.save(trip);

        // Update all riders in this trip
        await this.tripRiderRepo.update(
            { tripId: trip.id, status: TripRiderStatus.JOINED },
            { status: TripRiderStatus.NO_SHOW } // Driver cancelling typically means issue or no-show
        );

        // Free the driver
        await this.redisClient.del(`trip:driver:${trip.id}`);

        // Log event
        const event = this.eventRepo.create({
            tripId: trip.id,
            eventType: 'TRIP_CANCELLED',
            metadata: { reason: dto.reason, cancelledBy: driverId, role: 'DRIVER' },
        });
        await this.eventRepo.save(event);

        // Notify participants
        this.locationGateway.server.to(`trip:${trip.id}`).emit('trip_status_changed', {
            tripId: trip.id,
            oldStatus: trip.status, // previous state
            newStatus: TripStatus.CANCELLED,
            reason: dto.reason,
            cancelledBy: driverId,
        });

        return { success: true, message: 'Trip cancelled by driver' };
    }
}
