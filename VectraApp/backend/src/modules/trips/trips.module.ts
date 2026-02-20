import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TripEntity } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { TripRiderEntity } from './trip-rider.entity';
import { TripsService } from './trips.service';
import { TripsController } from './trips.controller';
import { LocationModule } from '../location/location.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([TripEntity, TripEventEntity, TripRiderEntity]),
    LocationModule,
  ],
  controllers: [TripsController],
  providers: [TripsService],
  exports: [TypeOrmModule, TripsService],
})
export class TripsModule { }
