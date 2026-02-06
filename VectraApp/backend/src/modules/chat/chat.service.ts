import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessageEntity } from './chat-message.entity';

@Injectable()
export class ChatService {
    constructor(
        @InjectRepository(ChatMessageEntity)
        private readonly chatRepo: Repository<ChatMessageEntity>,
    ) { }

    async saveMessage(tripId: string, senderId: string, message: string): Promise<ChatMessageEntity> {
        const chatMsg = this.chatRepo.create({
            tripId,
            senderId,
            message,
            isRead: false,
        });
        return await this.chatRepo.save(chatMsg);
    }

    async getMessagesForTrip(tripId: string): Promise<ChatMessageEntity[]> {
        return await this.chatRepo.find({
            where: { tripId },
            order: { sentAt: 'ASC' },
            relations: ['sender'], // load sender details if needed (e.g. name)
        });
    }
}
