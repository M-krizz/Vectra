import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DocumentsController } from './documents.controller';
import { AdminComplianceController } from './admin.controller';
import { DocumentsService } from './documents.service';
import { ComplianceService } from './compliance.service';
import { Document } from './entities/document.entity';
import { ComplianceEvent } from './entities/compliance-event.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { S3Service } from '../storage/s3.service';
import { User } from '../users/user.entity';
import { UsersModule } from '../users/users.module';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
  imports: [
    TypeOrmModule.forFeature([Document, ComplianceEvent, DriverProfile, User]),
    ScheduleModule.forRoot(),
    UsersModule,
  ],
  controllers: [DocumentsController, AdminComplianceController],
  providers: [DocumentsService, ComplianceService, S3Service],
  exports: [DocumentsService, ComplianceService],
})
export class ComplianceModule {}
