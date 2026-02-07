import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { Message } from './entities/message.entity';
import { RidesModule } from '../rides/rides.module';
import { UsersModule } from '../users/users.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Message]),
        RidesModule,
        UsersModule,
    ],
    providers: [ChatService, ChatGateway],
    exports: [ChatService],
})
export class ChatModule { }
