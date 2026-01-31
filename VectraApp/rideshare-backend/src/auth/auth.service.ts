import { Injectable, UnauthorizedException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from '../users/user.entity';
import * as bcrypt from 'bcrypt';
import { OtpService } from './otp.service';
import { RefreshToken } from './entities/refresh-token.entity';
import { DriverProfile, DriverStatus } from '../users/driver-profile.entity';
import ms from 'ms';

@Injectable()
export class AuthService {
  private accessExpiresIn: string;
  private refreshExpiresIn: string;
  private refreshHashRounds: number;

  constructor(
    private jwtService: JwtService,
    private otpService: OtpService,
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(RefreshToken) private refreshRepo: Repository<RefreshToken>,
    @InjectRepository(DriverProfile) private profilesRepo: Repository<DriverProfile>,
  ) {
    this.accessExpiresIn = process.env.JWT_EXPIRES_IN || '15m';
    this.refreshExpiresIn = process.env.REFRESH_TOKEN_EXPIRES_IN || '7d';
    this.refreshHashRounds = Number(process.env.REFRESH_TOKEN_HASH_SALT_ROUNDS || 12);
  }

  async validateLogin(email?: string, phone?: string, password?: string, otp?: string) {
    if ((!email && !phone) || (!password && !otp)) {
      throw new BadRequestException('Provide email/phone and password or otp');
    }

    const user = await this.usersRepo.findOne({ where: [{ email }, { phone }]});
    if (!user) throw new UnauthorizedException('Invalid credentials');

    // Drivers must be VERIFIED
    if (user.role === 'DRIVER') {
      const profile = await this.profilesRepo.findOne({ where: { user: { id: user.id } }, relations: ['user'] });
      if (!profile || profile.status !== DriverStatus.VERIFIED) {
        throw new ForbiddenException('Driver account not verified');
      }
    }

    // Riders must be verified for password login; OTP login will verify them
    if (user.role === 'RIDER' && !user.isVerified && !password && otp) {
      // allow OTP path below
    } else if (user.role === 'RIDER' && !user.isVerified && password) {
      throw new ForbiddenException('Account not verified. Please verify first.');
    }

    if (password) {
      if (!user.passwordHash) throw new UnauthorizedException('Invalid credentials');
      const ok = await bcrypt.compare(password, user.passwordHash);
      if (!ok) throw new UnauthorizedException('Invalid credentials');
      return user;
    }

    if (otp) {
      const target = phone ? `phone:${phone}` : `email:${email}`;
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

  async createSessionAndTokens(user: User, deviceInfo?: string, ip?: string) {
    const payload = { sub: user.id, role: user.role };
    const accessToken = await this.jwtService.signAsync(payload, {
      secret: process.env.JWT_SECRET,
      expiresIn: this.accessExpiresIn,
    });

    const refreshTokenRaw = await this.jwtService.signAsync({ sub: user.id }, {
      secret: process.env.JWT_SECRET,
      expiresIn: this.refreshExpiresIn,
    });

    const hashed = await bcrypt.hash(refreshTokenRaw, this.refreshHashRounds);

    const refreshTtlMs = ms(this.refreshExpiresIn) ?? (7 * 24 * 60 * 60 * 1000);
    const expiresAt = new Date(Date.now() + refreshTtlMs);

    const rt = this.refreshRepo.create({
      user,
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

  async rotateRefreshToken(refreshTokenRaw: string, refreshTokenId: string, deviceInfo?: string, ip?: string) {
    const record = await this.refreshRepo.findOne({ where: { id: refreshTokenId }, relations: ['user'] });
    if (!record) throw new UnauthorizedException('Invalid refresh token');

    if (record.expiresAt.getTime() < Date.now()) {
      await this.refreshRepo.delete({ id: record.id });
      throw new UnauthorizedException('Refresh token expired');
    }

    const match = await bcrypt.compare(refreshTokenRaw, record.tokenHash);
    if (!match) {
      await this.refreshRepo.delete({ user: { id: record.user.id } });
      throw new UnauthorizedException('Invalid refresh token (revoked all sessions)');
    }

    await this.refreshRepo.delete({ id: record.id });

    const user = record.user;
    return await this.createSessionAndTokens(user, deviceInfo ?? record.deviceInfo, ip ?? record.ip);
  }

  async revokeRefreshTokenById(tokenId: string, userId?: string) {
    const rec = await this.refreshRepo.findOne({ where: { id: tokenId }, relations: ['user'] });
    if (!rec) return false;
    if (userId && rec.user.id !== userId) {
      throw new UnauthorizedException('Not allowed');
    }
    await this.refreshRepo.delete({ id: tokenId });
    return true;
  }

  async revokeAllForUser(userId: string) {
    await this.refreshRepo.delete({ user: { id: userId }});
    return true;
  }

  async listSessions(userId: string) {
    const list = await this.refreshRepo.find({ where: { user: { id: userId } }, relations: ['user'] });
    return list.map(l => ({
      id: l.id,
      deviceInfo: l.deviceInfo,
      ip: l.ip,
      expiresAt: l.expiresAt,
      lastUsedAt: l.lastUsedAt,
      createdAt: l.createdAt,
    }));
  }

  async validateJwtPayload(payload: any) {
    if (!payload || !payload.sub) return null;
    const user = await this.usersRepo.findOne({ where: { id: payload.sub }});
    if (!user) return null;
    return user;
  }
}
