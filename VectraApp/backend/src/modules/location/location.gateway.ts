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
import { Injectable, Logger } from '@nestjs/common';
import Redis from 'ioredis';

@Injectable()
@WebSocketGateway({
  cors: { origin: '*' },
  namespace: 'location',
})
export class LocationGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  private redis: Redis;
  private readonly logger = new Logger(LocationGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor() {
    this.redis = new Redis(
      process.env.REDIS_URL || 'redis://localhost:6379',
    );
  }

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('update_location')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      lat: number;
      lng: number;
      driverId: string;
      rideId?: string;
    },
  ) {
    const { lat, lng, driverId, rideId } = data;
    const key = `driver:location:${driverId}`;

    // Store in Redis with TTL (30 seconds)
    await this.redis.setex(
      key,
      30,
      JSON.stringify({ lat, lng, ts: Date.now() }),
    );

    // If rideId is present, broadcast to the specific ride room
    if (rideId) {
      void this.server
        .to(`ride:${rideId}`)
        .emit('location_changed', { lat, lng, driverId });
    }

    // Also broadcast to a general "fleet" room for admins
    void this.server
      .to('admin:fleet')
      .emit('driver_moved', { lat, lng, driverId });
  }

  @SubscribeMessage('join_ride')
  handleJoinRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { rideId: string },
  ) {
    return client.join(`ride:${data.rideId}`);
  }

  @SubscribeMessage('join_fleet')
  handleJoinFleet(@ConnectedSocket() client: Socket) {
    return client.join('admin:fleet');
  }
}