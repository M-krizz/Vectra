import { Logger } from '@nestjs/common';
import { Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';

const logger = new Logger('SocketAuth');

export interface SocketJwtPayload {
  sub: string;
  role: string;
  iat?: number;
  exp?: number;
}

/**
 * Extracts the bearer token from a Socket.IO handshake.
 * Checks (in order): handshake.auth.token, Authorization header.
 */
export function extractSocketToken(socket: Socket): string | null {
  const authToken = socket.handshake.auth?.token as string | undefined;
  if (authToken) return authToken;

  const authHeader = socket.handshake.headers?.authorization as string | undefined;
  if (authHeader?.startsWith('Bearer ')) return authHeader.slice(7);

  return null;
}

/**
 * Validates a JWT from a socket handshake using NestJS JwtService.
 * Returns the decoded payload or null on failure.
 */
export async function validateSocketToken(
  jwtService: JwtService,
  token: string,
): Promise<SocketJwtPayload | null> {
  try {
    const payload = await jwtService.verifyAsync<SocketJwtPayload>(token, {
      secret: process.env.JWT_SECRET,
    });
    return payload;
  } catch (err: any) {
    logger.warn(`Socket JWT validation failed: ${err?.message ?? err}`);
    return null;
  }
}
