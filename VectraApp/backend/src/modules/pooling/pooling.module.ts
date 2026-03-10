import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PoolingService } from './pooling.service';
import { PoolGroupEntity } from './pool-group.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { TripEntity } from '../trips/trip.entity';
import { TripRiderEntity } from '../trips/trip-rider.entity';
import { PoolingManager } from './pooling.manager';
import { MlClientModule } from '../../integrations/ml-client/ml-client.module';
import { PoolingController } from './pooling.controller';
import { LocationModule } from '../location/location.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([
            PoolGroupEntity,
            RideRequestEntity,
            TripEntity,
            TripRiderEntity,
        ]),
        MlClientModule,
        LocationModule,
    ],
    controllers: [PoolingController],
    providers: [PoolingService, PoolingManager],
    exports: [PoolingService],
})
export class PoolingModule { }
