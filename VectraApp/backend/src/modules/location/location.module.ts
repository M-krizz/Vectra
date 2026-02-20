import { Module } from '@nestjs/common';
import { LocationGateway } from './location.gateway';
import { AuthenticationModule } from '../Authentication/authentication.module';
import { RedisModule } from '../../integrations/redis/redis.module';

@Module({
  imports: [AuthenticationModule, RedisModule],
  providers: [LocationGateway],
  exports: [LocationGateway],
})
export class LocationModule { }
