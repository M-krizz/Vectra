import { Module } from '@nestjs/common';
import { RealtimeModule } from '../../realtime/realtime.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TripEntity } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { TripRiderEntity } from './trip-rider.entity';
import { TripsService } from './trips.service';
import { TripsController } from './trips.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([TripEntity, TripEventEntity, TripRiderEntity]),
    RealtimeModule,
  ],
  controllers: [TripsController],
  providers: [TripsService],
  exports: [TypeOrmModule, TripsService],
})
export class TripsModule {}
