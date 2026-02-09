import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { MessageEntity } from './entities/message.entity';
import { RideRequestsModule } from '../ride_requests/ride-requests.module';
import { AuthenticationModule } from '../Authentication/authentication.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([MessageEntity]),
    RideRequestsModule,
    AuthenticationModule,
  ],
  providers: [ChatService, ChatGateway],
  exports: [ChatService],
})
export class ChatModule {}