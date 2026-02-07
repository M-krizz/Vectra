import {
    WebSocketGateway,
    WebSocketServer,
    SubscribeMessage,
    ConnectedSocket,
    MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { RidesService } from '../rides/rides.service';
import { UsersService } from '../users/users.service';

@WebSocketGateway({
    cors: { origin: '*' },
    namespace: 'chat',
})
export class ChatGateway {
    @WebSocketServer()
    server: Server;

    constructor(
        private chatService: ChatService,
        private ridesService: RidesService,
        private usersService: UsersService,
    ) { }

    @SubscribeMessage('send_message')
    async handleMessage(
        @ConnectedSocket() client: Socket,
        @MessageBody() data: { rideId: string; senderId: string; content: string },
    ) {
        const { rideId, senderId, content } = data;

        const ride = await this.ridesService.getRideDetails(rideId);
        const sender = await this.usersService.findById(senderId);

        if (ride && sender) {
            const savedMessage = await this.chatService.saveMessage(ride, sender, content);
            this.server.to(`ride:${rideId}`).emit('new_message', savedMessage);
        }
    }

    @SubscribeMessage('join_chat')
    handleJoinChat(@ConnectedSocket() client: Socket, @MessageBody() data: { rideId: string }) {
        client.join(`ride:${data.rideId}`);
    }
}
