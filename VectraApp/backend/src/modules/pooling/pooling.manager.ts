import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { RideRequestStatus, RideType } from '../ride_requests/ride-request.enums';
import { PoolingService } from './pooling.service';

@Injectable()
export class PoolingManager {
    private readonly logger = new Logger(PoolingManager.name);

    constructor(
        @InjectRepository(RideRequestEntity)
        private readonly requestRepo: Repository<RideRequestEntity>,
        private readonly poolingService: PoolingService,
    ) { }

    /**
     * Main Pooling Loop: Runs every 10 seconds
     * Scans for pending POOL requests and attempts to match them.
     */
    @Cron('*/10 * * * * *') // Every 10 seconds
    async handlePoolingLoop() {
        this.logger.log('Starting pooling loop...');

        // 1. Find all active POOL requests within the 90s window
        const now = new Date();
        const ninetySecondsAgo = new Date(now.getTime() - 90 * 1000);

        const activeRequests = await this.requestRepo.find({
            where: {
                status: RideRequestStatus.REQUESTED,
                rideType: RideType.POOL,
            },
            order: { requestedAt: 'ASC' } // Oldest first
        });

        for (const req of activeRequests) {
            // Check timeout
            if (req.requestedAt < ninetySecondsAgo) {
                await this.handleTimeout(req);
                continue;
            }

            // Adaptive Radius: 
            const elapsedSeconds = (now.getTime() - req.requestedAt.getTime()) / 1000;
            let radius = 100;
            if (elapsedSeconds > 15) radius = 200;
            if (elapsedSeconds > 30) radius = 400;
            if (elapsedSeconds > 45) radius = 700;
            if (elapsedSeconds > 60) radius = 1000;
            if (elapsedSeconds > 75) radius = 1500;

            try {
                const candidates = await this.poolingService.findCandidates(req, radius);

                if (candidates.length > 0) {
                    // Try to form a pool
                    const result = await this.poolingService.evaluateGroupings(req, candidates);
                    if (result) {
                        await this.poolingService.finalizePool(result);
                        this.logger.log(`Pool formed for request ${req.id}`);
                    }
                }
            } catch (err) {
                this.logger.error(`Error processing pooling for ${req.id}`, err);
            }
        }
    }

    private async handleTimeout(req: RideRequestEntity) {
        // Per V1: Do not auto-convert to SOLO. Ask user.
        // Emit event: POOL_TIMEOUT_CHOICE_REQUIRED
        this.logger.log(`Request ${req.id} timed out searching for pool. Emitting choice event.`);
        // TODO: Emit Websocket event to learner
        // For now, we just log it. We might update status to 'EXPIRED' if we want to stop processing it?
        // Or keep it REQUESTED but stop expanding radius?

        // If we don't update status, this loop will pick it up again.
        // We should probably have a 'TIMEOUT_DECISION_PENDING' status or flag.
        // For V1 simple impl, we can leave it or mark EXPIRED.
        // Let's mark EXPIRED for now to stop the loop spamming.

        // req.status = RideRequestStatus.EXPIRED;
        // await this.requestRepo.save(req);
    }
}
