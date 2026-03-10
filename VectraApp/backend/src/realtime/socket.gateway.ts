import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
  WsException,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import Redis from 'ioredis';
import { Inject } from '@nestjs/common';
import { REDIS } from '../integrations/redis/redis.module';
import { extractSocketToken, validateSocketToken } from './socket.auth';

// Key helpers for Redis driver-socket mapping
const driverSocketKey = (userId: string) => `driver:socket:${userId}`;
const socketUserKey = (socketId: string) => `socket:user:${socketId}`;

@Injectable()
@WebSocketGateway({
  namespace: '/realtime',
  cors: {
    origin: process.env.CORS_ALLOWED_ORIGINS
      ? process.env.CORS_ALLOWED_ORIGINS.split(',').map((o) => o.trim())
      : true,
    credentials: true,
  },
})
export class RealTimeGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(RealTimeGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwtService: JwtService,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  // ──────────────────────────────────────────────────────────────
  // Lifecycle hooks
  // ──────────────────────────────────────────────────────────────

  async handleConnection(client: Socket) {
    const token = extractSocketToken(client);
    if (!token) {
      this.logger.warn(`[Realtime] No token from ${client.id} — disconnecting`);
      client.disconnect();
      return;
    }

    const payload = await validateSocketToken(this.jwtService, token);
    if (!payload) {
      this.logger.warn(`[Realtime] Invalid token from ${client.id} — disconnecting`);
      client.disconnect();
      return;
    }

    const { sub: userId, role } = payload;

    // Attach user context to the socket for later handler access
    (client as any).userId = userId;
    (client as any).role = role;

    // Map userId ↔ socketId in Redis (TTL 24h)
    await this.redis.setex(driverSocketKey(userId), 86400, client.id);
    await this.redis.setex(socketUserKey(client.id), 86400, userId);

    // Join personal room so server-side push is trivial
    await client.join(`user:${userId}`);

    // Drivers also join a shared room for broadcast ride offers
    if (role === 'DRIVER') {
      await client.join('drivers');
    }

    this.logger.log(`[Realtime] ${role} ${userId} connected (${client.id})`);
  }

  async handleDisconnect(client: Socket) {
    const userId: string | undefined = (client as any).userId;
    if (userId) {
      await this.redis.del(driverSocketKey(userId));
      await this.redis.del(socketUserKey(client.id));
      this.logger.log(`[Realtime] User ${userId} disconnected (${client.id})`);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Server-to-Driver: Push a ride offer to a specific driver
  // ──────────────────────────────────────────────────────────────

  /**
   * Called by the matching/trip service to push a ride offer to a driver.
   * payload must conform to the RideRequest model on the Flutter side.
   */
  async sendRideOffer(driverUserId: string, payload: Record<string, unknown>) {
    this.server.to(`user:${driverUserId}`).emit('ride_offered', payload);
    this.logger.log(`[Realtime] ride_offered → driver ${driverUserId}`);
  }

  /**
   * Broadcast heatmap update to all connected drivers.
   */
  async broadcastHeatmap(heatmapData: unknown[]) {
    this.server.to('drivers').emit('heatmap_update', { hexagons: heatmapData });
  }

  // ──────────────────────────────────────────────────────────────
  // Client-to-Server: Driver accepts a ride
  // ──────────────────────────────────────────────────────────────

  @SubscribeMessage('driver:accept_ride')
  async handleAcceptRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { rideRequestId: string; tripId: string },
  ) {
    const driverUserId: string | undefined = (client as any).userId;
    if (!driverUserId) throw new WsException('Unauthenticated');

    const { rideRequestId, tripId } = body ?? {};
    if (!rideRequestId && !tripId) {
      throw new WsException('rideRequestId or tripId is required');
    }

    const id = tripId ?? rideRequestId;
    this.logger.log(`[Realtime] driver:accept_ride — driver ${driverUserId} ride ${id}`);

    // Notify rider's room
    this.server.to(`ride:${id}`).emit('ride_accepted', {
      driverUserId,
      tripId: id,
      timestamp: new Date().toISOString(),
    });

    // Acknowledge to the driver
    return { status: 'ok', tripId: id };
  }

  // ──────────────────────────────────────────────────────────────
  // Client-to-Server: Driver rejects / declines a ride
  // ──────────────────────────────────────────────────────────────

  @SubscribeMessage('driver:reject_ride')
  async handleRejectRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { rideRequestId: string; tripId?: string; reason?: string },
  ) {
    const driverUserId: string | undefined = (client as any).userId;
    if (!driverUserId) throw new WsException('Unauthenticated');

    const id = body?.tripId ?? body?.rideRequestId;
    if (!id) throw new WsException('rideRequestId is required');

    this.logger.log(`[Realtime] driver:reject_ride — driver ${driverUserId} ride ${id}`);

    // Notify matching service / rider that this driver declined
    this.server.to(`ride:${id}`).emit('ride_rejected', {
      driverUserId,
      tripId: id,
      reason: body?.reason ?? 'declined',
      timestamp: new Date().toISOString(),
    });

    return { status: 'ok', tripId: id };
  }

  // ──────────────────────────────────────────────────────────────
  // Client-to-Server: Join a specific trip room (for live tracking)
  // ──────────────────────────────────────────────────────────────

  @SubscribeMessage('join_trip')
  async handleJoinTrip(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { tripId: string },
  ) {
    const userId: string | undefined = (client as any).userId;
    if (!userId) throw new WsException('Unauthenticated');

    const { tripId } = body ?? {};
    if (!tripId) throw new WsException('tripId is required');

    await client.join(`ride:${tripId}`);
    this.logger.log(`[Realtime] User ${userId} joined trip room ride:${tripId}`);
    return { status: 'ok', tripId };
  }

  // ──────────────────────────────────────────────────────────────
  // Client-to-Server: Leave a trip room
  // ──────────────────────────────────────────────────────────────

  @SubscribeMessage('leave_trip')
  async handleLeaveTrip(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { tripId: string },
  ) {
    const userId: string | undefined = (client as any).userId;
    if (!userId) throw new WsException('Unauthenticated');

    const { tripId } = body ?? {};
    if (!tripId) throw new WsException('tripId is required');

    await client.leave(`ride:${tripId}`);
    return { status: 'ok' };
  }
}
