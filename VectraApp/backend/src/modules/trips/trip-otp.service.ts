import {
    Injectable,
    NotFoundException,
    BadRequestException,
    Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TripEntity, TripStatus } from './trip.entity';
import { LocationGateway } from '../location/location.gateway';
import Redis from 'ioredis';
import { Inject } from '@nestjs/common';
import { REDIS } from '../../integrations/redis/redis.module';

const OTP_TTL = 600; // 10 minutes

@Injectable()
export class TripOtpService {
    private readonly logger = new Logger(TripOtpService.name);

    constructor(
        @InjectRepository(TripEntity)
        private readonly tripRepo: Repository<TripEntity>,
        private readonly locationGateway: LocationGateway,
        @Inject(REDIS) private readonly redisClient: Redis,
    ) { }

    /** Generate a 4-digit OTP, store in Redis, return it. */
    async generateOtp(tripId: string, riderId: string): Promise<string> {
        const trip = await this.tripRepo.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');
        if (trip.status !== TripStatus.ARRIVING) {
            throw new BadRequestException('OTP can only be generated when driver is ARRIVING');
        }

        const otp = Math.floor(1000 + Math.random() * 9000).toString();
        await this.redisClient.setex(`trip:otp:${tripId}:${riderId}`, OTP_TTL, otp);
        this.logger.log(`OTP generated for trip ${tripId}, rider ${riderId}`);

        // Emit OTP to rider's personal channel (so it shows on their screen)
        this.locationGateway.server.to(`user:${riderId}`).emit('trip_otp', { tripId, otp });

        return otp;
    }

    /**
     * Driver submits OTP entered by rider.
     * On success → emits otp_verified, driver can now change status to IN_PROGRESS.
     */
    async verifyOtp(tripId: string, riderId: string, submittedOtp: string): Promise<boolean> {
        const storedOtp = await this.redisClient.get(`trip:otp:${tripId}:${riderId}`);
        if (!storedOtp) {
            throw new BadRequestException('OTP expired or not generated. Request a new one.');
        }
        if (storedOtp !== submittedOtp) {
            throw new BadRequestException('Incorrect OTP');
        }

        // Delete OTP to prevent replay
        await this.redisClient.del(`trip:otp:${tripId}:${riderId}`);

        // Notify everyone in trip room that OTP is verified
        this.locationGateway.server.to(`trip:${tripId}`).emit('otp_verified', {
            tripId,
            riderId,
        });

        this.logger.log(`OTP verified for trip ${tripId}, rider ${riderId}`);
        return true;
    }
}
