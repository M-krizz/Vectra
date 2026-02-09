import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { RideRequestsService } from '../ride_requests/ride-requests.service';
import { UsersService } from '../Authentication/users/users.service';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: 'chat',
})
export class ChatGateway {
  @WebSocketServer()
  server!: Server;

  constructor(
    private chatService: ChatService,
    private rideRequestsService: RideRequestsService,
    private usersService: UsersService,
  ) {}

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { rideId: string; senderId: string; content: string },
  ) {
    const { rideId, senderId, content } = data;

    const ride = await this.rideRequestsService.getRequest(rideId);
    const sender = await this.usersService.findById(senderId);

    if (ride && sender) {
      const savedMessage = await this.chatService.saveMessage(
        ride,
        sender,
        content,
      );
      this.server.to(`ride:${rideId}`).emit('new_message', savedMessage);
    }
  }

  @SubscribeMessage('join_chat')
  handleJoinChat(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { rideId: string },
  ) {
    client.join(`ride:${data.rideId}`);
  }
}