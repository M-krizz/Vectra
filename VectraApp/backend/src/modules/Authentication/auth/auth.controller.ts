import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  UseGuards,
  Ip,
  Headers,
  Patch,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import {
  RequestOtpDto,
  VerifyOtpDto,
  RefreshDto,
  CompleteProfileDto,
} from './dto/auth.dto';

@Controller('api/v1/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post('request-otp')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestOtp(dto.channel, dto.identifier);
  }

  @Post('verify-otp')
  verifyOtp(
    @Body() dto: VerifyOtpDto,
    @Ip() ip: string,
    @Headers('user-agent') userAgent: string,
    @Headers('x-role-hint') roleHint: string,
  ) {
    return this.authService.verifyOtpAndLogin(
      dto.identifier,
      dto.code,
      roleHint as any,
      userAgent,
      ip,
    );
  }

  @Patch('complete-profile')
  @UseGuards(JwtAuthGuard)
  completeProfile(
    @Req() req: { user: { userId: string } },
    @Body() dto: CompleteProfileDto,
  ) {
    return this.authService.completeProfile(req.user.userId, dto.fullName);
  }

  @Post('refresh')
  refresh(
    @Body() dto: RefreshDto,
    @Ip() ip: string,
    @Headers('user-agent') userAgent: string,
    @Headers('x-refresh-token-id') tokenId: string,
  ) {
    return this.authService.rotateRefreshToken(
      dto.refreshToken,
      tokenId,
      userAgent,
      ip,
    );
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  logout(
    @Headers('x-refresh-token-id') tokenId: string,
    @Req() req: { user: { userId: string } },
  ) {
    return this.authService.revokeRefreshTokenById(tokenId, req.user.userId);
  }

  @Post('logout-all')
  @UseGuards(JwtAuthGuard)
  logoutAll(@Req() req: { user: { userId: string } }) {
    return this.authService.revokeAllForUser(req.user.userId);
  }

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  listSessions(@Req() req: { user: { userId: string } }) {
    return this.authService.listSessions(req.user.userId);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@Req() req: { user: { userId: string } }) {
    return this.authService.getMe(req.user.userId);
  }
}
