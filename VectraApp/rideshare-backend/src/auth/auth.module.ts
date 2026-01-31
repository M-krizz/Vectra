import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthService } from './auth.service';
import { JwtStrategy } from './jwt.strategy';
import { AuthController } from './auth.controller';
import { RefreshToken } from './entities/refresh-token.entity';
import { User } from '../users/user.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { OtpService } from './otp.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_SECRET,
    }),
    TypeOrmModule.forFeature([RefreshToken, User, DriverProfile]),
  ],
  providers: [AuthService, JwtStrategy, OtpService, JwtAuthGuard],
  controllers: [AuthController],
  exports: [AuthService],
})
export class AuthModule {}
