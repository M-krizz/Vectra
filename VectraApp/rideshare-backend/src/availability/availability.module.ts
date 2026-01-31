import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AvailabilityController } from './availability.controller';
import { AvailabilityService } from './availability.service';
import { WeeklySchedule } from './entities/weekly-schedule.entity';
import { TimeOff } from './entities/timeoff.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { UsersModule } from '../users/users.module';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Module({
  imports: [
    TypeOrmModule.forFeature([WeeklySchedule, TimeOff, DriverProfile]),
    UsersModule,
  ],
  controllers: [AvailabilityController],
  providers: [AvailabilityService, JwtAuthGuard],
  exports: [AvailabilityService],
})
export class AvailabilityModule {}
