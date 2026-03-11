import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CancellationsController } from './cancellations.controller';
import { CancellationsService } from './cancellations.service';
import { TripEntity } from '../trips/trip.entity';
import { TripEventEntity } from '../trips/trip-event.entity';
import { TripRiderEntity } from '../trips/trip-rider.entity';
import { LocationModule } from '../location/location.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([
            TripEntity,
            TripEventEntity,
            TripRiderEntity,
        ]),
        LocationModule,
        PaymentsModule,
    ],
    controllers: [CancellationsController],
    providers: [CancellationsService],
    exports: [CancellationsService],
})
export class CancellationsModule { }
