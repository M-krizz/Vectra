import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MatchingService } from './matching.service';
import { MatchingManager } from './matching.manager';
import { UserEntity } from '../Authentication/users/user.entity';
import { DriverProfileEntity } from '../Authentication/drivers/driver-profile.entity';
import { TripEntity } from '../trips/trip.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { LocationModule } from '../location/location.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([
            UserEntity,
            DriverProfileEntity,
            TripEntity,
            RideRequestEntity,
        ]),
        LocationModule,
    ],
    providers: [MatchingService, MatchingManager],
    exports: [MatchingService],
})
export class MatchingModule { }
