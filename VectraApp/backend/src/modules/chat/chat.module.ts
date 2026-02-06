import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatGateway } from './chat.gateway';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { ChatMessageEntity } from './chat-message.entity';

@Module({
    imports: [TypeOrmModule.forFeature([ChatMessageEntity])],
    providers: [ChatGateway, ChatService],
    controllers: [ChatController],
    exports: [ChatService],
})
export class ChatModule { }
