import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './user.entity';
import { DriverProfile } from './driver-profile.entity';
import { Vehicle } from './vehicle.entity';
import { Document } from './document.entity';
import { DriversService } from './drivers.service';
import { DriversController } from './drivers.controller';
import { DocumentsService } from '../documents/documents.service';
import { DocumentsController } from '../documents/documents.controller';
import { S3Service } from '../storage/s3.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, DriverProfile, Vehicle, Document])],
  providers: [DriversService, DocumentsService, S3Service],
  controllers: [DriversController, DocumentsController],
  exports: [DriversService],
})
export class UsersModule {}
