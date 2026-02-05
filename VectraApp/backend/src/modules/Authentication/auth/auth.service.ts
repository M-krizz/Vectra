import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Repository, IsNull } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { UserEntity, UserRole } from '../users/user.entity';
import { RefreshTokenEntity } from './refresh-token.entity';
import {
  DriverProfileEntity,
  DriverStatus,
} from '../drivers/driver-profile.entity';
import { OtpService } from './otp.service';

@Injectable()
export class AuthService {
  private accessExpiresIn: string;
  private refreshExpiresIn: string;
  private refreshHashRounds: number;

  constructor(
    private jwtService: JwtService,
    private otpService: OtpService,
    @InjectRepository(UserEntity) private usersRepo: Repository<UserEntity>,
    @InjectRepository(RefreshTokenEntity)
    private refreshRepo: Repository<RefreshTokenEntity>,
    @InjectRepository(DriverProfileEntity)
    private profilesRepo: Repository<DriverProfileEntity>,
  ) {
    this.accessExpiresIn = process.env.JWT_ACCESS_EXPIRES_IN || '15m';
    this.refreshExpiresIn = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
    this.refreshHashRounds = Number(
      process.env.REFRESH_TOKEN_HASH_SALT_ROUNDS || 12,
    );
  }

  private parseExpiryToSeconds(exp: string): number {
    const m = exp.match(/^(\d+)([smhd])$/);
    if (!m) return 15 * 60; // default 15m
    const n = Number(m[1]);
    const unit = m[2];
    if (unit === 's') return n;
    if (unit === 'm') return n * 60;
    if (unit === 'h') return n * 3600;
    return n * 86400; // d
  }

  /**
   * Request OTP for phone or email
   */
  async requestOtp(channel: 'phone' | 'email', identifier: string) {
    return this.otpService.requestOtp(channel, identifier);
  }

  /**
   * Verify OTP and create user if not exists
   */
  async verifyOtpAndLogin(
    identifier: string,
    code: string,
    roleHint?: UserRole,
    deviceInfo?: string,
    ip?: string,
  ) {
    const verified = await this.otpService.verifyOtp(identifier, code);
    if (!verified) {
      throw new UnauthorizedException('Invalid OTP.');
    }

    const isEmail = identifier.includes('@');
    let user = await this.usersRepo.findOne({
      where: isEmail ? { email: identifier } : { phone: identifier },
    });

    if (!user) {
      user = this.usersRepo.create({
        role: roleHint || UserRole.RIDER,
        email: isEmail ? identifier : null,
        phone: isEmail ? null : identifier,
        isVerified: true,
      });
      user = await this.usersRepo.save(user);
    } else {
      // Mark as verified
      if (!user.isVerified) {
        user.isVerified = true;
        await this.usersRepo.save(user);
      }
    }

    // Check driver verification
    if (user.role === UserRole.DRIVER) {
      const profile = await this.profilesRepo.findOne({
        where: { userId: user.id },
      });
      if (!profile || profile.status !== DriverStatus.VERIFIED) {
        throw new ForbiddenException('Driver account not verified');
      }
    }

    // Update last login
    user.lastLoginAt = new Date();
    await this.usersRepo.save(user);

    const tokens = await this.createSessionAndTokens(user, deviceInfo, ip);

    return {
      user: {
        id: user.id,
        role: user.role,
        email: user.email,
        phone: user.phone,
        fullName: user.fullName,
      },
      ...tokens,
    };
  }

  /**
   * Login with email/phone and password or OTP
   */
  async validateLogin(
    email?: string,
    phone?: string,
    password?: string,
    otp?: string,
  ) {
    if ((!email && !phone) || (!password && !otp)) {
      throw new BadRequestException('Provide email/phone and password or otp');
    }

    const user = await this.usersRepo.findOne({
      where: email ? { email } : { phone },
    });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    // Check if user is suspended
    if (user.isSuspended) {
      throw new ForbiddenException(
        `Account suspended: ${user.suspensionReason || 'Contact support'}`,
      );
    }

    // Drivers must be VERIFIED
    if (user.role === UserRole.DRIVER) {
      const profile = await this.profilesRepo.findOne({
        where: { userId: user.id },
      });
      if (!profile || profile.status !== DriverStatus.VERIFIED) {
        throw new ForbiddenException('Driver account not verified');
      }
    }

    if (password) {
      if (!user.passwordHash)
        throw new UnauthorizedException('Invalid credentials');
      const ok = await bcrypt.compare(password, user.passwordHash);
      if (!ok) throw new UnauthorizedException('Invalid credentials');
      return user;
    }

    if (otp) {
      const target = phone || email || '';
      const verified = await this.otpService.verifyOtp(target, otp);
      if (!verified) throw new UnauthorizedException('Invalid OTP');
      if (!user.isVerified) {
        user.isVerified = true;
        await this.usersRepo.save(user);
      }
      return user;
    }

    throw new BadRequestException('Invalid login flow');
  }

  /**
   * Create session with access and refresh tokens
   */
  async createSessionAndTokens(
    user: UserEntity,
    deviceInfo?: string,
    ip?: string,
  ) {
    const payload = { sub: user.id, role: user.role };
    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_ACCESS_SECRET as string,
      expiresIn: this.parseExpiryToSeconds(this.accessExpiresIn),
    });

    const refreshTokenRaw = this.jwtService.sign(
      { sub: user.id },
      {
        secret: process.env.JWT_REFRESH_SECRET as string,
        expiresIn: this.parseExpiryToSeconds(this.refreshExpiresIn),
      },
    );

    const hashed = await bcrypt.hash(refreshTokenRaw, this.refreshHashRounds);

    const refreshTtlMs =
      this.parseExpiryToSeconds(this.refreshExpiresIn) * 1000;
    const expiresAt = new Date(Date.now() + refreshTtlMs);

    const rt = this.refreshRepo.create({
      userId: user.id,
      tokenHash: hashed,
      deviceInfo: deviceInfo ?? null,
      ip: ip ?? null,
      expiresAt,
      lastUsedAt: new Date(),
    });
    const saved = await this.refreshRepo.save(rt);

    return {
      accessToken,
      refreshToken: refreshTokenRaw,
      refreshTokenId: saved.id,
      accessExpiresIn: this.accessExpiresIn,
      refreshExpiresAt: saved.expiresAt,
    };
  }

  /**
   * Rotate refresh token
   */
  async rotateRefreshToken(
    refreshTokenRaw: string,
    refreshTokenId: string,
    deviceInfo?: string,
    ip?: string,
  ) {
    const record = await this.refreshRepo.findOne({
      where: { id: refreshTokenId },
    });
    if (!record) throw new UnauthorizedException('Invalid refresh token');

    if (record.revokedAt) {
      throw new UnauthorizedException('Refresh token revoked');
    }

    if (record.expiresAt.getTime() < Date.now()) {
      await this.refreshRepo.delete({ id: record.id });
      throw new UnauthorizedException('Refresh token expired');
    }

    const match = await bcrypt.compare(refreshTokenRaw, record.tokenHash);
    if (!match) {
      // Potential token theft - revoke all sessions
      await this.refreshRepo.update(
        { userId: record.userId },
        { revokedAt: new Date() },
      );
      throw new UnauthorizedException(
        'Invalid refresh token (revoked all sessions)',
      );
    }

    // Revoke old token
    record.revokedAt = new Date();
    await this.refreshRepo.save(record);

    const user = await this.usersRepo.findOne({ where: { id: record.userId } });
    if (!user) throw new UnauthorizedException('User not found');

    return await this.createSessionAndTokens(
      user,
      deviceInfo ?? record.deviceInfo ?? undefined,
      ip ?? record.ip ?? undefined,
    );
  }

  /**
   * Revoke specific refresh token
   */
  async revokeRefreshTokenById(tokenId: string, userId?: string) {
    const record = await this.refreshRepo.findOne({ where: { id: tokenId } });
    if (!record) return false;
    if (userId && record.userId !== userId) {
      throw new UnauthorizedException('Not allowed');
    }
    record.revokedAt = new Date();
    await this.refreshRepo.save(record);
    return true;
  }

  /**
   * Revoke all sessions for user (logout everywhere)
   */
  async revokeAllForUser(userId: string) {
    await this.refreshRepo.update({ userId }, { revokedAt: new Date() });
    return true;
  }

  /**
   * List active sessions
   */
  async listSessions(userId: string) {
    const list = await this.refreshRepo.find({
      where: { userId, revokedAt: IsNull() },
    });
    return list.map((l) => ({
      id: l.id,
      deviceInfo: l.deviceInfo,
      ip: l.ip,
      expiresAt: l.expiresAt,
      lastUsedAt: l.lastUsedAt,
      createdAt: l.createdAt,
    }));
  }

  /**
   * Get current user
   */
  async getMe(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('User not found');
    return {
      id: user.id,
      role: user.role,
      email: user.email,
      phone: user.phone,
      fullName: user.fullName,
      status: user.status,
      isVerified: user.isVerified,
      createdAt: user.createdAt,
    };
  }

  /**
   * Validate JWT payload
   */
  async validateJwtPayload(payload: { sub: string; role: string }) {
    if (!payload || !payload.sub) return null;
    const user = await this.usersRepo.findOne({ where: { id: payload.sub } });
    if (!user || user.isSuspended) return null;
    return user;
  }
}
