import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SafetyService } from './safety.service';
import { SafetyController } from './safety.controller';
import { IncidentEntity } from './entities/incident.entity';
import { EmergencyContactEntity } from './entities/emergency-contact.entity';
import { AuthenticationModule } from '../Authentication/authentication.module';
import { LocationModule } from '../location/location.module';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      IncidentEntity,
      EmergencyContactEntity,
      RideRequestEntity,
    ]),
    AuthenticationModule,
    LocationModule,
  ],
  controllers: [SafetyController],
  providers: [SafetyService],
  exports: [SafetyService],
})
export class SafetyModule { }
