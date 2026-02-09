import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SafetyService } from './safety.service';
import { SafetyController } from './safety.controller';
import { IncidentEntity } from './entities/incident.entity';
import { AuthenticationModule } from '../Authentication/authentication.module';

@Module({
  imports: [TypeOrmModule.forFeature([IncidentEntity]), AuthenticationModule],
  controllers: [SafetyController],
  providers: [SafetyService],
  exports: [SafetyService],
})
export class SafetyModule {}