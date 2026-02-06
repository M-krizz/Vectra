import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RideRequestsController } from './ride-requests.controller';
import { RideRequestsService } from './ride-requests.service';
import { RideRequestEntity } from './ride-request.entity';
import { RedisModule } from '../../integrations/redis/redis.module';
import { GoogleMapsModule } from '../../integrations/google-maps/google-maps.module';

@Module({
    exports: [TypeOrmModule],
})
export class RideRequestsModule { }
