import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import Redis from 'ioredis';
import * as bcrypt from 'bcrypt';
import { REDIS } from '../../../integrations/redis/redis.module';

const otpKey = (identifier: string) => `otp:${identifier}`;
const otpAttemptsKey = (identifier: string) => `otp_attempts:${identifier}`;
const otpCooldownKey = (identifier: string) => `otp_cooldown:${identifier}`;

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  /**
   * Send OTP via Fast2SMS (Quick SMS Route)
   */
  private async sendSmsViaFast2Sms(
    phone: string,
    otp: string,
  ): Promise<boolean> {
    const apiKey = process.env.FAST2SMS_API_KEY;
    if (!apiKey) {
      this.logger.warn('Fast2SMS API key not configured, skipping SMS send');
      return false;
    }

    // Clean phone number (remove +91 or leading 0)
    const cleanPhone = phone.replace(/^\+91/, '').replace(/^0/, '');
    // Ensure it's 10 digits
    if (cleanPhone.length !== 10) {
      this.logger.error(`Invalid phone number format: ${phone}`);
      return false;
    }

    try {
      const response = await fetch('https://www.fast2sms.com/dev/bulkV2', {
        method: 'POST',
        headers: {
          authorization: apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          route: 'q', // Quick SMS route (no DLT template required)
          message: `Your Vectra verification code is: ${otp}. Valid for 5 minutes.`,
          language: 'english',
          flash: 0,
          numbers: cleanPhone,
        }),
      });

      const result = (await response.json()) as {
        return: boolean;
        message: string;
        request_id?: string;
      };
      this.logger.log(`Fast2SMS Response: ${JSON.stringify(result)}`);

      if (result.return) {
        this.logger.log(`OTP sent successfully to ${cleanPhone}`);
        return true;
      } else {
        this.logger.error(`Fast2SMS error: ${result.message}`);
        return false;
      }
    } catch (error) {
      this.logger.error(`Failed to send SMS: ${error}`);
      return false;
    }
  }

  /**
   * Request OTP - stores hashed OTP in Redis with rate limiting
   */
  async requestOtp(channel: 'phone' | 'email', identifier: string) {
    const cooldownSeconds = Number(
      process.env.OTP_REQUEST_COOLDOWN_SECONDS || 30,
    );
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
    await this.redis.set(
      otpCooldownKey(identifier),
      '1',
      'EX',
      cooldownSeconds,
    );

    // Send OTP via SMS if enabled and channel is phone
    const isDev = (process.env.NODE_ENV || 'development') !== 'production';
    const smsEnabled = process.env.FAST2SMS_ENABLED === 'true';

    if (channel === 'phone' && smsEnabled) {
      await this.sendSmsViaFast2Sms(identifier, code);
    }

    return {
      success: true,
      channel,
      identifier,
      expiresInSeconds: ttlSeconds,
      // Return OTP in dev mode for testing (remove in production)
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
    const attempts = Number(
      (await this.redis.get(otpAttemptsKey(identifier))) || 0,
    );
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
