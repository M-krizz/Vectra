import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RideRequestEntity } from './ride-request.entity';
import { RideRequestsService } from './ride-requests.service';
import { RideRequestsController } from './ride-requests.controller';
import { TripEntity } from '../trips/trip.entity';
import { TripRiderEntity } from '../trips/trip-rider.entity';
import { FareModule } from '../fare/fare.module';
import { MapsModule } from '../maps/maps.module';
import { LocationModule } from '../location/location.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([RideRequestEntity, TripEntity, TripRiderEntity]),
    FareModule,
    MapsModule,
    LocationModule,
  ],
  controllers: [RideRequestsController],
  providers: [RideRequestsService],
  exports: [TypeOrmModule, RideRequestsService],
})
export class RideRequestsModule {}
