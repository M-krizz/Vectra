import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TripEntity } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { TripRiderEntity } from './trip-rider.entity';
import { TripsService } from './trips.service';
import { TripOtpService } from './trip-otp.service';
import { TripsController } from './trips.controller';
import { LocationModule } from '../location/location.module';
import { FareModule } from '../fare/fare.module';
import { MapsModule } from '../maps/maps.module';
import { DriverProfileEntity } from '../Authentication/drivers/driver-profile.entity';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      TripEntity,
      TripEventEntity,
      TripRiderEntity,
      DriverProfileEntity,
    ]),
    forwardRef(() => LocationModule),
    FareModule,
    MapsModule,
    forwardRef(() => PaymentsModule),
  ],
  controllers: [TripsController],
  providers: [TripsService, TripOtpService],
  exports: [TypeOrmModule, TripsService],
})
export class TripsModule { }
