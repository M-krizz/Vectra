import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import Redis from 'ioredis';
import * as bcrypt from 'bcrypt';
import { REDIS } from '../../../integrations/redis/redis.module';

const otpKey = (identifier: string) => `otp:${identifier}`;
const otpAttemptsKey = (identifier: string) => `otp_attempts:${identifier}`;
const otpCooldownKey = (identifier: string) => `otp_cooldown:${identifier}`;

@Injectable()
export class OtpService {
    constructor(@Inject(REDIS) private readonly redis: Redis) { }

    /**
     * Request OTP - stores hashed OTP in Redis with rate limiting
     */
    async requestOtp(channel: 'phone' | 'email', identifier: string) {
        const cooldownSeconds = Number(process.env.OTP_REQUEST_COOLDOWN_SECONDS || 30);
        const cooldown = await this.redis.get(otpCooldownKey(identifier));
        if (cooldown) {
            throw new HttpException(
                'Please wait before requesting OTP again.',
                HttpStatus.TOO_MANY_REQUESTS,
            );
        }

        const ttlSeconds = Number(process.env.OTP_TTL_SECONDS || 300);

        // Generate 6-digit OTP
        const code = String(Math.floor(100000 + Math.random() * 900000));

        // Store hash in Redis (never store raw OTP)
        const codeHash = await bcrypt.hash(code, 10);
        await this.redis.set(otpKey(identifier), codeHash, 'EX', ttlSeconds);

        // Reset attempts and set cooldown
        await this.redis.del(otpAttemptsKey(identifier));
        await this.redis.set(otpCooldownKey(identifier), '1', 'EX', cooldownSeconds);

        // For dev: return OTP in response for easy testing
        const isDev = (process.env.NODE_ENV || 'development') !== 'production';
        return {
            success: true,
            channel,
            identifier,
            expiresInSeconds: ttlSeconds,
            ...(isDev ? { devOtp: code } : {}),
        };
    }

    /**
     * Verify OTP - checks attempt limits and validates against stored hash
     */
    async verifyOtp(identifier: string, code: string): Promise<boolean> {
        const hash = await this.redis.get(otpKey(identifier));
        if (!hash) {
            return false;
        }

        // Check attempt limits
        const maxAttempts = Number(process.env.OTP_MAX_VERIFY_ATTEMPTS || 5);
        const attempts = Number((await this.redis.get(otpAttemptsKey(identifier))) || 0);
        if (attempts >= maxAttempts) {
            throw new HttpException(
                'Too many attempts. Request OTP again.',
                HttpStatus.TOO_MANY_REQUESTS,
            );
        }

        const ok = await bcrypt.compare(code, hash);
        if (!ok) {
            await this.redis.incr(otpAttemptsKey(identifier));
            await this.redis.expire(
                otpAttemptsKey(identifier),
                Number(process.env.OTP_TTL_SECONDS || 300),
            );
            return false;
        }

        // OTP is correct => remove it (one-time use)
        await this.redis.del(otpKey(identifier));
        await this.redis.del(otpAttemptsKey(identifier));

        return true;
    }
}
