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
import { Injectable, Logger, Inject } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS } from '../../integrations/redis/redis.module';
import { AuthService } from '../Authentication/auth/auth.service';

@Injectable()
@WebSocketGateway({
  cors: { origin: '*' },
})
export class LocationGateway
  implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(LocationGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    @Inject(REDIS) private readonly redisClient: Redis,
    private readonly authService: AuthService,
  ) { }

  async handleConnection(client: Socket) {
    try {
      // 1. Authenticate via Headers or Auth object
      const token =
        client.handshake.headers['authorization']?.toString()?.replace('Bearer ', '') ||
        client.handshake.auth?.token;

      if (!token) {
        this.logger.warn(`Connection attempt without token: ${client.id}`);
        client.disconnect();
        return;
      }

      const payload = await this.authService.verifyAccessToken(token);
      if (!payload) {
        this.logger.warn(`Invalid token connection attempt: ${client.id}`);
        client.disconnect();
        return;
      }

      const userId = payload.sub;
      const role = payload.role;

      // 2. Attach user info to socket
      (client as any).userId = userId;
      (client as any).role = role;

      // 3. User-Socket Mapping in Redis
      // Store socketId for direct notifications later
      await this.redisClient.setex(`socket:user:${userId}`, 3600, client.id);

      this.logger.log(`User ${userId} (${role}) connected: ${client.id}`);

      // Auto-join personal room for direct messages/notifications
      await client.join(`user:${userId}`);
    } catch (err) {
      this.logger.error(`Error handling connection: ${err.message}`);
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = (client as any).userId;
    if (userId) {
      await this.redisClient.del(`socket:user:${userId}`);
      this.logger.log(`User ${userId} disconnected: ${client.id}`);
    }
  }

  // --- GPS Data Ingestion (Driver Module 2) ---

  @SubscribeMessage('update_location')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      lat: number;
      lng: number;
      heading?: number;
      speed?: number;
    },
  ) {
    const userId = (client as any).userId;
    const role = (client as any).role;

    if (role !== 'DRIVER') return;

    const key = `driver:location:${userId}`;

    // Store in Redis with TTL (60 seconds)
    // Using a more structured format for ML service consumption
    const locationData = {
      lat: data.lat,
      lng: data.lng,
      heading: data.heading || 0,
      speed: data.speed || 0,
      updatedAt: new Date().toISOString(),
    };

    await this.redisClient.setex(key, 60, JSON.stringify(locationData));

    // Add to Geospatial Index for matching (Module 1.5)
    // REDIS GEOADD uses: key, longitude, latitude, member
    await this.redisClient.geoadd('drivers:geo', data.lng, data.lat, userId);
    await this.redisClient.expire('drivers:geo', 60); // Keep index fresh

    // Broadcast to any rooms listening for this driver (e.g., active trip)
    // We check if driver is in a trip room
    const tripId = (Array.from(client.rooms) as string[]).find(r => r.startsWith('trip:'))?.split(':')[1];
    if (tripId) {
      this.server.to(`trip:${tripId}`).emit('driver_moved', {
        driverId: userId,
        ...locationData,
      });
    }

    // Also broadcast to fleet room for admins
    this.server.to('admin:fleet').emit('fleet_update', {
      driverId: userId,
      ...locationData,
    });
  }

  // --- Trip Status & Communication (Module 1.9) ---

  @SubscribeMessage('join_trip')
  async handleJoinTrip(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { tripId: string },
  ) {
    this.logger.debug(`User ${(client as any).userId} joining trip room: ${data.tripId}`);
    return client.join(`trip:${data.tripId}`);
  }

  @SubscribeMessage('leave_trip')
  async handleLeaveTrip(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { tripId: string },
  ) {
    return client.leave(`trip:${data.tripId}`);
  }

  // --- Admin Fleet Monitoring (Admin Module 2) ---

  @SubscribeMessage('join_fleet')
  async handleJoinFleet(@ConnectedSocket() client: Socket) {
    if ((client as any).role === 'ADMIN') {
      this.logger.log(`Admin ${(client as any).userId} joined fleet room`);
      return client.join('admin:fleet');
    }
  }
}
