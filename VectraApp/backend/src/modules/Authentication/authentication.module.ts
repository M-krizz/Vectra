import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';

// Entities
import { UserEntity } from './users/user.entity';
import { DriverProfileEntity } from './drivers/driver-profile.entity';
import { VehicleEntity } from './drivers/vehicle.entity';
import { RefreshTokenEntity } from './auth/refresh-token.entity';
import { DocumentEntity } from './compliance/document.entity';
import { ComplianceEventEntity } from './compliance/compliance-event.entity';
import { AdminAuditEntity } from './admin/admin-audit.entity';
import { RoleChangeAuditEntity } from './rbac/role-change-audit.entity';

// Services
import { OtpService } from './auth/otp.service';
import { AuthService } from './auth/auth.service';
import { UsersService } from './users/users.service';
import { DriversService } from './drivers/drivers.service';
import { ProfileService } from './profile/profile.service';
import { AdminService } from './admin/admin.service';
import { RbacService } from './rbac/rbac.service';

// Controllers
import { AuthController } from './auth/auth.controller';
import { AdminController } from './admin/admin.controller';
import { ProfileController } from './profile/profile.controller';
import { DriversController } from './drivers/drivers.controller';

// Strategies & Guards
import { JwtStrategy } from './auth/jwt.strategy';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { PermissionsGuard } from './common/permissions.guard';
import { RolesGuard } from './common/roles.guard';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserEntity,
      DriverProfileEntity,
      VehicleEntity,
      RefreshTokenEntity,
      DocumentEntity,
      ComplianceEventEntity,
      AdminAuditEntity,
      RoleChangeAuditEntity,
    ]),
    PassportModule,
    JwtModule.register({
      secret: process.env.JWT_ACCESS_SECRET || 'fallback_secret',
      signOptions: { expiresIn: 900 },
    }),
  ],
  controllers: [
    AuthController,
    AdminController,
    ProfileController,
    DriversController,
  ],
  providers: [
    // Services
    OtpService,
    AuthService,
    UsersService,
    DriversService,
    ProfileService,
    AdminService,
    RbacService,
    // Strategy & Guards
    JwtStrategy,
    JwtAuthGuard,
    PermissionsGuard,
    RolesGuard,
  ],
  exports: [
    AuthService,
    UsersService,
    RbacService,
    JwtAuthGuard,
    PermissionsGuard,
    RolesGuard,
    TypeOrmModule,
  ],
})
export class AuthenticationModule {}
