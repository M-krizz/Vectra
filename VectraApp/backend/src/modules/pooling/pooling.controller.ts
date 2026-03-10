import { Controller, Get, Post, Body, Query, UseGuards, Req } from '@nestjs/common';
import { PoolingService } from './pooling.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';
import { InjectRepository } from '@nestjs/typeorm';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { Repository } from 'typeorm';

@Controller('api/v1/pooling')
@UseGuards(JwtAuthGuard)
export class PoolingController {
    constructor(
        private readonly poolingService: PoolingService,
        @InjectRepository(RideRequestEntity)
        private readonly requestRepo: Repository<RideRequestEntity>,
    ) { }

    @Get('candidates')
    async getCandidates(
        @Query('requestId') requestId: string,
        @Query('radius') radius: string,
    ) {
        const request = await this.requestRepo.findOne({ where: { id: requestId } });
        if (!request) return [];

        const radiusMeters = parseInt(radius) || 2000;
        return this.poolingService.findCandidates(request, radiusMeters);
    }

    @Post('finalize')
    async finalizePool(@Body() body: { riderIds: string[] }) {
        // This is a simplified version for the mobile app to trigger a pool formation
        // In production, the PoolingManager cron usually handles this automatically.
        const requests = await this.requestRepo.findByIds(body.riderIds);
        if (requests.length === 0) return { success: false, message: 'No requests found' };

        const tripId = await this.poolingService.finalizePool({ riders: requests });
        return { success: !!tripId, tripId };
    }
}
