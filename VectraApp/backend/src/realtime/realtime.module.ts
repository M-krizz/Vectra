import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { RealTimeGateway } from './socket.gateway';
import { RedisModule } from '../integrations/redis/redis.module';

@Module({
  imports: [
    RedisModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: { expiresIn: 900 }, // 15 minutes in seconds
    }),
  ],
  providers: [RealTimeGateway],
  exports: [RealTimeGateway],
})
export class RealtimeModule {}
