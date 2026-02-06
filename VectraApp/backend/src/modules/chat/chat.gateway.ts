import {
    WebSocketGateway,
    WebSocketServer,
    SubscribeMessage,
    OnGatewayConnection,
    OnGatewayDisconnect,
    ConnectedSocket,
    MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger, UseGuards } from '@nestjs/common';
import { ChatService } from './chat.service';

// We might want to use a guard here to ensure only authenticated users can connect/send.
// For MVP, we pass userId in handshake or just trust the socket (less secure).
// Ideally, use jwt-auth adapter.

@WebSocketGateway({
    cors: {
        origin: '*',
    },
    namespace: 'chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer()
    server!: Server;

    private logger = new Logger('ChatGateway');

    constructor(private readonly chatService: ChatService) { }

    handleConnection(client: Socket) {
        this.logger.log(`Client connected: ${client.id}`);
    }

    handleDisconnect(client: Socket) {
        this.logger.log(`Client disconnected: ${client.id}`);
    }

    @SubscribeMessage('join_trip')
    handleJoinTrip(
        @ConnectedSocket() client: Socket,
        @MessageBody() payload: { tripId: string; userId: string },
    ) {
        this.logger.log(`User ${payload.userId} joining trip room: ${payload.tripId}`);
        client.join(`trip_${payload.tripId}`);
        return { event: 'joined', success: true, tripId: payload.tripId };
    }

    @SubscribeMessage('send_message')
    async handleSendMessage(
        @ConnectedSocket() client: Socket,
        @MessageBody() payload: { tripId: string; senderId: string; message: string },
    ) {
        this.logger.log(`Msg from ${payload.senderId} in ${payload.tripId}: ${payload.message}`);

        // 1. Persist message
        const savedMsg = await this.chatService.saveMessage(
            payload.tripId,
            payload.senderId,
            payload.message,
        );

        // 2. Broadcast to room (including sender, or use client.to(...).emit to exclude sender)
        // client.to(`trip_${payload.tripId}`).emit('new_message', savedMsg); 
        // Using server.to() ensures everyone in the room gets it, including sender (confirmation)
        this.server.to(`trip_${payload.tripId}`).emit('new_message', savedMsg);

        return savedMsg;
    }
}
