import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { OtpService } from './otp.service';

@Controller('auth/otp')
export class OtpController {
  constructor(private otpService: OtpService) {}

  @Post('generate')
  async generate(@Body() body: { target: string }) {
    // target: "phone:+9198..." or "email:foo@bar.com"
    if (!body.target) throw new BadRequestException('target required');
    const otp = await this.otpService.generateOtp(body.target);
    // NOTE: do NOT return OTP in production. Here for dev/test only.
    // In prod, call your SMS/email provider and return a terse success.
    return { status: 'sent', debugOtp: otp };
  }

  @Post('verify')
  async verify(@Body() body: { target: string; otp: string }) {
    if (!body.target || !body.otp) throw new BadRequestException('target & otp required');
    const ok = await this.otpService.verifyOtp(body.target, body.otp);
    if (!ok) return { status: 'invalid' };
    return { status: 'verified' };
  }
}
