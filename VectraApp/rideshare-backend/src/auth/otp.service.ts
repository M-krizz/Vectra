import { Injectable, BadRequestException } from '@nestjs/common';
import Redis from 'ioredis';
import { randomInt } from 'crypto';

@Injectable()
export class OtpService {
  private redis: Redis;
  private OTP_TTL: number;
  private OTP_PREFIX = 'otp:';
  private OTP_RATE_PREFIX = 'otp_rate:';
  private OTP_MAX_PER_HOUR: number;

  constructor() {
    this.redis = new Redis(process.env.REDIS_URL);
    this.OTP_TTL = Number(process.env.OTP_TTL_SECONDS || 300);
    this.OTP_MAX_PER_HOUR = Number(process.env.OTP_MAX_PER_HOUR || 10);
  }

  private keyFor(target: string) {
    return `${this.OTP_PREFIX}${target}`;
  }

  private rateKey(target: string) {
    return `${this.OTP_RATE_PREFIX}${target}`;
  }

  async generateOtp(target: string) {
    const rk = this.rateKey(target);
    const calls = await this.redis.incr(rk);
    if (calls === 1) {
      await this.redis.expire(rk, 60 * 60);
    }
    if (calls > this.OTP_MAX_PER_HOUR) {
      throw new BadRequestException('OTP request rate limit reached');
    }

    const otp = (100000 + randomInt(900000)).toString();
    await this.redis.setex(this.keyFor(target), this.OTP_TTL, otp);
    return otp;
  }

  async verifyOtp(target: string, otp: string) {
    const key = this.keyFor(target);
    const real = await this.redis.get(key);
    if (!real) return false;
    if (real !== otp) return false;
    await this.redis.del(key);
    return true;
  }
}
