import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';
import { TripEntity } from '../trips/trip.entity';
import { UserEntity } from '../Authentication/users/user.entity';

@Module({
    imports: [TypeOrmModule.forFeature([TripEntity, UserEntity])],
    controllers: [AnalyticsController],
    providers: [AnalyticsService],
})
export class AnalyticsModule { }
