import { Injectable, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import Redis from 'ioredis';
import * as bcrypt from 'bcrypt';
import { Twilio } from 'twilio';
import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';
import axios from 'axios';
import { REDIS } from '../../../integrations/redis/redis.module';

const otpKey = (identifier: string) => `otp:${identifier}`;
const otpAttemptsKey = (identifier: string) => `otp_attempts:${identifier}`;
const otpCooldownKey = (identifier: string) => `otp_cooldown:${identifier}`;

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  private readonly twilioClient: Twilio | null;
  private readonly mailer: Transporter | null;
  private readonly fast2smsApiKey: string | null;
  private readonly isDev =
    (process.env.NODE_ENV || 'development') !== 'production';
  private readonly devBypassOtp = process.env.OTP_DEV_BYPASS_CODE || '000000';
  private redisFallbackLogged = false;
  private readonly memoryStore = new Map<
    string,
    { value: string; expiresAt?: number }
  >();

  constructor(@Inject(REDIS) private readonly redis: Redis) {
    // Fast2SMS SMS provider (preferred over Twilio when configured)
    this.fast2smsApiKey = process.env.FAST2SMS_API_KEY ?? null;
    if (!this.fast2smsApiKey) {
      this.logger.warn('FAST2SMS_API_KEY not configured. Falling back to Twilio for SMS.');
    }

    const sid = process.env.TWILIO_SID;
    const token = process.env.TWILIO_AUTH_TOKEN;
    if (sid && token) {
      this.twilioClient = new Twilio(sid, token);
    } else {
      this.twilioClient = null;
      if (!this.fast2smsApiKey) {
        this.logger.warn('Neither Fast2SMS nor Twilio credentials configured. SMS will not be sent.');
      }
    }

    const smtpHost = process.env.SMTP_HOST || 'smtp.gmail.com';
    const smtpPort = Number(process.env.SMTP_PORT || 587);
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;
    const smtpSecure = (process.env.SMTP_SECURE || 'false') === 'true';

    if (smtpUser && smtpPass) {
      this.mailer = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpSecure,
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });
    } else {
      this.mailer = null;
      this.logger.warn('SMTP credentials not configured. Email OTP will not be sent.');
    }
  }

  private logRedisFallback(error: unknown) {
    if (this.redisFallbackLogged) return;
    this.redisFallbackLogged = true;
    this.logger.warn(
      `Redis unavailable, using in-memory OTP fallback in development. Error: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  private getMemory(key: string): string | null {
    const entry = this.memoryStore.get(key);
    if (!entry) return null;
    if (entry.expiresAt && entry.expiresAt <= Date.now()) {
      this.memoryStore.delete(key);
      return null;
    }
    return entry.value;
  }

  private setMemory(key: string, value: string, ttlSeconds?: number): void {
    this.memoryStore.set(key, {
      value,
      expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined,
    });
  }

  private delMemory(key: string): void {
    this.memoryStore.delete(key);
  }

  private incrMemory(key: string): number {
    const current = Number(this.getMemory(key) || 0);
    const next = current + 1;
    const existing = this.memoryStore.get(key);
    this.memoryStore.set(key, { value: String(next), expiresAt: existing?.expiresAt });
    return next;
  }

  private async safeGet(key: string): Promise<string | null> {
    try {
      return await this.redis.get(key);
    } catch (error) {
      if (!this.isDev) {
        throw new HttpException('OTP service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
      }
      this.logRedisFallback(error);
      return this.getMemory(key);
    }
  }

  private async safeSet(key: string, value: string, ttlSeconds?: number): Promise<void> {
    try {
      if (ttlSeconds) {
        await this.redis.set(key, value, 'EX', ttlSeconds);
      } else {
        await this.redis.set(key, value);
      }
    } catch (error) {
      if (!this.isDev) {
        throw new HttpException('OTP service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
      }
      this.logRedisFallback(error);
      this.setMemory(key, value, ttlSeconds);
    }
  }

  private async safeDel(key: string): Promise<void> {
    try {
      await this.redis.del(key);
    } catch (error) {
      if (!this.isDev) {
        throw new HttpException('OTP service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
      }
      this.logRedisFallback(error);
      this.delMemory(key);
    }
  }

  private async safeIncr(key: string): Promise<number> {
    try {
      return await this.redis.incr(key);
    } catch (error) {
      if (!this.isDev) {
        throw new HttpException('OTP service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
      }
      this.logRedisFallback(error);
      return this.incrMemory(key);
    }
  }

  private async safeExpire(key: string, ttlSeconds: number): Promise<void> {
    try {
      await this.redis.expire(key, ttlSeconds);
    } catch (error) {
      if (!this.isDev) {
        throw new HttpException('OTP service unavailable', HttpStatus.SERVICE_UNAVAILABLE);
      }
      this.logRedisFallback(error);
      const value = this.getMemory(key);
      if (value !== null) {
        this.setMemory(key, value, ttlSeconds);
      }
    }
  }

  /**
   * Send OTP via Fast2SMS BulkV2 API (preferred India SMS provider).
   * Strips +91 country code if present.
   */
  private async sendSmsFast2SMS(phone: string, otp: string): Promise<boolean> {
    if (!this.fast2smsApiKey) {
      return false;
    }

    // Strip country code for Fast2SMS (expects 10-digit Indian mobile)
    const cleanPhone = phone.startsWith('+91')
      ? phone.slice(3)
      : phone.startsWith('91') && phone.length === 12
        ? phone.slice(2)
        : phone;

    try {
      const response = await axios.post<{ return: boolean; request_id?: string; message?: string[] }>(
        'https://www.fast2sms.com/dev/bulkV2',
        {
          route: 'otp',
          variables_values: otp,
          numbers: cleanPhone,
          flash: '0',
        },
        {
          headers: {
            authorization: this.fast2smsApiKey,
            'Content-Type': 'application/json',
          },
          timeout: 10_000,
        },
      );

      if (response.data?.return === true) {
        this.logger.log(`[Fast2SMS] OTP sent to ${cleanPhone}`);
        return true;
      }

      this.logger.error(
        `[Fast2SMS] Unexpected response: ${JSON.stringify(response.data)}`,
      );
      return false;
    } catch (error: any) {
      this.logger.error(
        `[Fast2SMS] Failed to send OTP to ${cleanPhone} | ${error?.message ?? 'unknown error'} | Response: ${JSON.stringify(error?.response?.data ?? {})}`,
      );
      return false;
    }
  }

  /**
   * Send OTP via Twilio SMS (fallback)
   */
  private async sendSmsTwilio(phone: string, otp: string): Promise<boolean> {
    if (!this.twilioClient) {
      this.logger.warn('Twilio client not initialized, skipping SMS send');
      return false;
    }

    const from = process.env.TWILIO_FROM;
    if (!from) {
      this.logger.error('TWILIO_FROM not set in environment');
      return false;
    }

    try {
      const message = await this.twilioClient.messages.create({
        body: `Your Vectra verification code is: ${otp}. Valid for 5 minutes. Do not share this with anyone.`,
        from,
        to: phone,
      });
      this.logger.log(`Twilio SMS sent to ${phone}. SID: ${message.sid}`);
      return true;
    } catch (error: any) {
      this.logger.error(
        `[Twilio] Failed to send SMS to ${phone} | Code: ${error?.code ?? 'N/A'} | ${error?.message}`,
      );
      if (error?.code === 21608) {
        this.logger.error(
          `[Twilio] TRIAL ACCOUNT: The number ${phone} is NOT verified. Go to https://console.twilio.com/us1/develop/phone-numbers/manage/verified and add it.`,
        );
      }
      return false;
    }
  }

  /**
   * Send OTP via SMTP email
   */
  private async sendEmailOtp(email: string, otp: string): Promise<boolean> {
    if (!this.mailer) {
      this.logger.warn('SMTP transporter not initialized, skipping email send');
      return false;
    }

    const from = process.env.SMTP_FROM || process.env.SMTP_USER;
    if (!from) {
      this.logger.error('SMTP_FROM (or SMTP_USER) is not set in environment');
      return false;
    }

    try {
      await this.mailer.sendMail({
        from,
        to: email,
        subject: 'Vectra OTP Verification Code',
        text: `Your Vectra verification code is: ${otp}. It is valid for 5 minutes. Do not share this code with anyone.`,
        html: `<p>Your Vectra verification code is: <b>${otp}</b></p><p>This code is valid for 5 minutes.</p><p>Do not share this code with anyone.</p>`,
      });
      this.logger.log(`OTP email sent to ${email}`);
      return true;
    } catch (error: any) {
      this.logger.error(
        `[SMTP] Failed to send OTP email to ${email} | ${error?.message ?? 'unknown error'}`,
      );
      return false;
    }
  }

  /**
   * Request OTP - stores hashed OTP in Redis with rate limiting
   */
  async requestOtp(channel: 'phone' | 'email', identifier: string) {
    const cooldownSeconds = Number(process.env.OTP_REQUEST_COOLDOWN_SECONDS || 30);
    const cooldown = await this.safeGet(otpCooldownKey(identifier));
    if (cooldown) {
      throw new HttpException(
        'Please wait before requesting OTP again.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const ttlSeconds = Number(process.env.OTP_TTL_SECONDS || 300);

    // Generate 6-digit OTP
    const code = String(Math.floor(100000 + Math.random() * 900000));

    // Store hashed OTP in Redis (never store raw OTP)
    const codeHash = await bcrypt.hash(code, 10);
    await this.safeSet(otpKey(identifier), codeHash, ttlSeconds);

    // Reset attempts and set cooldown
    await this.safeDel(otpAttemptsKey(identifier));
    await this.safeSet(otpCooldownKey(identifier), '1', cooldownSeconds);

    // Send OTP to the appropriate channel
    const emailEnabled = (process.env.SMTP_EMAIL_ENABLED || 'true') === 'true';
    const isDev = this.isDev;

    if (channel === 'phone') {
      // Prefer Fast2SMS, fall back to Twilio
      let smsSent = false;
      if (this.fast2smsApiKey) {
        smsSent = await this.sendSmsFast2SMS(identifier, code);
      }
      if (!smsSent && this.twilioClient) {
        smsSent = await this.sendSmsTwilio(identifier, code);
      }
      if (!smsSent) {
        this.logger.warn(`SMS OTP could not be delivered to ${identifier}. OTP available in dev logs.`);
      }
    }

    if (channel === 'email' && emailEnabled) {
      const sent = await this.sendEmailOtp(identifier, code);
      if (!sent) {
        this.logger.warn(`Email OTP failed for ${identifier}. OTP available in dev logs.`);
      }
    }

    // Log OTP in server console in dev mode (never expose in API response)
    if (isDev) {
      this.logger.log(`[DEV] OTP for ${identifier}: ${code}`);
    }

    return {
      success: true,
      channel,
      identifier,
      expiresInSeconds: ttlSeconds,
    };
  }

  /**
   * Verify OTP - checks attempt limits and validates against stored hash
   */
  async verifyOtp(identifier: string, code: string): Promise<boolean> {
    if (this.isDev && code === this.devBypassOtp) {
      await this.safeDel(otpKey(identifier));
      await this.safeDel(otpAttemptsKey(identifier));
      return true;
    }

    const hash = await this.safeGet(otpKey(identifier));
    if (!hash) {
      return false;
    }

    // Check attempt limits
    const maxAttempts = Number(process.env.OTP_MAX_VERIFY_ATTEMPTS || 5);
    const attempts = Number(
      (await this.safeGet(otpAttemptsKey(identifier))) || 0,
    );
    if (attempts >= maxAttempts) {
      throw new HttpException(
        'Too many attempts. Request OTP again.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const ok = await bcrypt.compare(code, hash);
    if (!ok) {
      await this.safeIncr(otpAttemptsKey(identifier));
      await this.safeExpire(
        otpAttemptsKey(identifier),
        Number(process.env.OTP_TTL_SECONDS || 300),
      );
      return false;
    }

    // OTP is correct → remove it (one-time use)
    await this.safeDel(otpKey(identifier));
    await this.safeDel(otpAttemptsKey(identifier));

    return true;
  }
}
