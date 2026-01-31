import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../users/user.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { AdminAudit } from '../audit/admin-audit.entity';
import { RbacModule } from '../rbac/rbac.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, DriverProfile, AdminAudit]),
    RbacModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
