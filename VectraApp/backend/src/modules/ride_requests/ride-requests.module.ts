import { Module } from '@nestjs/common';
import { RealtimeModule } from '../../realtime/realtime.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RideRequestEntity } from './ride-request.entity';
import { RideRequestsService } from './ride-requests.service';
import { RideRequestsController } from './ride-requests.controller';

@Module({
  imports: [TypeOrmModule.forFeature([RideRequestEntity]), RealtimeModule],
  controllers: [RideRequestsController],
  providers: [RideRequestsService],
  exports: [TypeOrmModule, RideRequestsService],
})
export class RideRequestsModule { }
