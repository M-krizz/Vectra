import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { RbacModule } from './rbac/rbac.module';
import { RoleChangeAudit } from './rbac/role-change-audit.entity';
import { ProfileModule } from './profile/profile.module';
import { ComplianceModule } from './compliance/compliance.module';
import { AvailabilityModule } from './availability/availability.module';
import { RidesModule } from './rides/rides.module';
import { LocationModule } from './location/location.module';
import { ChatModule } from './chat/chat.module';
import { SafetyModule } from './safety/safety.module';
@Module({
  imports: [
    TypeOrmModule.forRoot({
      // keep your existing DB config
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT || 5432),
      username: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'ride_platform',
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: true, // dev only
    }),
    UsersModule,
    AuthModule,
    RbacModule,
    AdminModule,
    ProfileModule,
    TypeOrmModule.forFeature([RoleChangeAudit]),
    ComplianceModule,
    AvailabilityModule,
    RidesModule,
    LocationModule,
    ChatModule,
    SafetyModule,
  ],
})
export class AppModule { }
