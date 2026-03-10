import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
@Injectable()
export class SocketGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private logger: Logger = new Logger('SocketGateway');

  afterInit(_server: Server) {
    this.logger.log('WebSocket Gateway Initialized');
  }

  handleConnection(client: Socket, ..._args: unknown[]) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('authenticate')
  handleAuthenticate(
    @MessageBody() data: { token: string },
    @ConnectedSocket() client: Socket,
  ) {
    // In a real app, verify the token here using JwtService
    // Optionally attach user info to the socket
    this.logger.log(`Client authenticated: ${client.id}`);
    client.emit('authenticated', { status: 'success' });
  }

  @SubscribeMessage('join_trip_room')
  handleJoinTripRoom(
    @MessageBody() data: { tripId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { tripId } = data;
    if (tripId) {
      void client.join(`trip_${tripId}`);
      this.logger.log(`Client ${client.id} joined trip room: trip_${tripId}`);
    }
  }

  @SubscribeMessage('leave_trip_room')
  handleLeaveTripRoom(
    @MessageBody() data: { tripId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { tripId } = data;
    if (tripId) {
      void client.leave(`trip_${tripId}`);
      this.logger.log(`Client ${client.id} left trip room: trip_${tripId}`);
    }
  }

  // Helper method to emit trip status to all clients in a trip room
  emitTripStatus(
    tripId: string,
    status: string,
    payload: Record<string, unknown> = {},
  ) {
    this.server.to(`trip_${tripId}`).emit('trip_status', {
      tripId,
      status,
      ...payload,
    });
    this.logger.log(`Emitted trip_status: ${status} for trip_${tripId}`);
  }

  // Helper method to emit location updates to all clients in a trip room
  emitLocationUpdate(
    tripId: string,
    lat: number,
    lng: number,
    etaSeconds?: number,
  ) {
    this.server.to(`trip_${tripId}`).emit('location_update', {
      tripId,
      lat,
      lng,
      etaSeconds,
    });
  }
}
