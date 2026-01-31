import { Controller, Post, Body, UseGuards, Req, Get, Param, Delete } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { Request } from 'express';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const user = await this.authService.validateLogin(dto.email, dto.phone, dto.password, dto.otp);
    const session = await this.authService.createSessionAndTokens(user, dto.deviceInfo, dto.ip);
    return { status: 'ok', user: { id: user.id, fullName: user.fullName, role: user.role }, ...session };
  }

  @Post('refresh')
  async refresh(@Body() body: { refreshTokenId: string; refreshToken: string; deviceInfo?: string; ip?: string }) {
    const result = await this.authService.rotateRefreshToken(body.refreshToken, body.refreshTokenId, body.deviceInfo, body.ip);
    return { status: 'ok', ...result };
  }

  @Post('logout')
  async logout(@Body() body: { refreshTokenId: string }) {
    await this.authService.revokeRefreshTokenById(body.refreshTokenId);
    return { status: 'ok' };
  }

  @UseGuards(JwtAuthGuard)
  @Get('sessions')
  async sessions(@Req() req: Request) {
    const user: any = (req as any).user;
    const list = await this.authService.listSessions(user.id);
    return { status: 'ok', sessions: list };
  }

  @UseGuards(JwtAuthGuard)
  @Delete('sessions/:id')
  async revokeSession(@Req() req: Request, @Param('id') id: string) {
    const user: any = (req as any).user;
    await this.authService.revokeRefreshTokenById(id, user.id);
    return { status: 'ok' };
  }

  @UseGuards(JwtAuthGuard)
  @Post('revoke-all')
  async revokeAll(@Req() req: Request) {
    const user: any = (req as any).user;
    await this.authService.revokeAllForUser(user.id);
    return { status: 'ok' };
  }
}
