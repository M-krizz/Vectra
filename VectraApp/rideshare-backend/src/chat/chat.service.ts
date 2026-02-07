import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './entities/message.entity';
import { User } from '../users/user.entity';
import { RideRequest } from '../rides/entities/ride-request.entity';

@Injectable()
export class ChatService {
    constructor(
        @InjectRepository(Message)
        private messageRepo: Repository<Message>,
    ) { }

    async saveMessage(ride: RideRequest, sender: User, content: string) {
        const message = this.messageRepo.create({
            ride,
            sender,
            content,
        });
        return this.messageRepo.save(message);
    }

    async getChatHistory(rideId: string) {
        return this.messageRepo.find({
            where: { ride: { id: rideId } },
            relations: ['sender'],
            order: { createdAt: 'ASC' },
        });
    }
}
