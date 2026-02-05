import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AuthService } from './auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_ACCESS_SECRET || 'fallback_secret',
    });
  }

  async validate(payload: { sub: string; role: string }) {
    const user = await this.authService.validateJwtPayload(payload);
    if (!user) return null;
    return { userId: payload.sub, role: payload.role };
  }
}
