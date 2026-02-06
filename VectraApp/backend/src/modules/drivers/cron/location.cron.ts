import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { RedisService } from '../../integrations/redis/redis.service';

@Injectable()
export class LocationCronService {
    private readonly logger = new Logger(LocationCronService.name);

    constructor(private readonly redisService: RedisService) { }

    // Run every minute
    @Cron(CronExpression.EVERY_MINUTE)
    async handleCleanup() {
        this.logger.debug('Running stale driver location cleanup...');
        
        const fiveMinutesAgo = Date.now() - (5 * 60 * 1000);
        const staleDriverIds = await this.redisService.getInactiveDrivers(fiveMinutesAgo);
        
        if (staleDriverIds.length > 0) {
            this.logger.log(`Found ${staleDriverIds.length} stale drivers. Removing...`);
            
            // Remove from GEO index
            const pipeline = this.redisService.getRedisClient().pipeline();
            pipeline.zrem('drivers:locations', ...staleDriverIds);
            pipeline.zrem('drivers:heartbeat', ...staleDriverIds);
            await pipeline.exec();
            
            this.logger.log(`Removed ${staleDriverIds.length} stale drivers.`);
        }
    }
}
