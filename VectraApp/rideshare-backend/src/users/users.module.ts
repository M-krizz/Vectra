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
import { UsersService } from './users.service';
import { UsersController } from './users.controller';

@Module({
  imports: [TypeOrmModule.forFeature([User, DriverProfile, Vehicle, Document])],
  providers: [DriversService, DocumentsService, S3Service, UsersService],
  controllers: [DriversController, DocumentsController, UsersController],
  exports: [DriversService, UsersService],
})
export class UsersModule { }
