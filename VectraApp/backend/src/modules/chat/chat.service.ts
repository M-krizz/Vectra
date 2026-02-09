import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MessageEntity } from './entities/message.entity';
import { UserEntity } from '../Authentication/users/user.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(MessageEntity)
    private messageRepo: Repository<MessageEntity>,
  ) {}

  async saveMessage(
    ride: RideRequestEntity,
    sender: UserEntity,
    content: string,
  ): Promise<MessageEntity> {
    const message = this.messageRepo.create({
      ride,
      sender,
      content,
    });
    return this.messageRepo.save(message);
  }

  async getChatHistory(rideId: string): Promise<MessageEntity[]> {
    return this.messageRepo.find({
      where: { ride: { id: rideId } },
      relations: ['sender'],
      order: { createdAt: 'ASC' },
    });
  }
}