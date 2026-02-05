import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { UserEntity, UserRole } from '../users/user.entity';
import { DriverProfileEntity } from '../drivers/driver-profile.entity';
import { AdminAuditEntity, AdminAction } from './admin-audit.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(UserEntity) private usersRepo: Repository<UserEntity>,
    @InjectRepository(DriverProfileEntity)
    private driverRepo: Repository<DriverProfileEntity>,
    @InjectRepository(AdminAuditEntity)
    private auditRepo: Repository<AdminAuditEntity>,
  ) {}

  async listUsers() {
    return this.usersRepo.find({
      where: { deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
  }

  async getUserDetails(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    let driverProfile = null;
    if (user.role === UserRole.DRIVER) {
      driverProfile = await this.driverRepo.findOne({
        where: { userId: user.id },
      });
    }

    return { user, driverProfile };
  }

  async suspendUser(
    targetUserId: string,
    adminUserId: string,
    reason?: string,
  ) {
    const user = await this.usersRepo.findOne({ where: { id: targetUserId } });
    if (!user) throw new NotFoundException('User not found');

    user.isSuspended = true;
    user.suspensionReason = reason ?? 'Violation of terms';
    await this.usersRepo.save(user);

    await this.auditRepo.save({
      targetUserId,
      performedById: adminUserId,
      action: AdminAction.SUSPEND_USER,
      reason,
    });

    return user;
  }

  async reinstateUser(targetUserId: string, adminUserId: string) {
    const user = await this.usersRepo.findOne({ where: { id: targetUserId } });
    if (!user) throw new NotFoundException('User not found');

    user.isSuspended = false;
    user.suspensionReason = null;
    await this.usersRepo.save(user);

    await this.auditRepo.save({
      targetUserId,
      performedById: adminUserId,
      action: AdminAction.REINSTATE_USER,
      reason: null,
    });

    return user;
  }
}
