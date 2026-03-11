import { Module, forwardRef } from '@nestjs/common';
import { LocationGateway } from './location.gateway';
import { AuthenticationModule } from '../Authentication/authentication.module';
import { RedisModule } from '../../integrations/redis/redis.module';
import { TripsModule } from '../trips/trips.module';

@Module({
  imports: [AuthenticationModule, RedisModule, forwardRef(() => TripsModule)],
  providers: [LocationGateway],
  exports: [LocationGateway],
})
export class LocationModule { }
