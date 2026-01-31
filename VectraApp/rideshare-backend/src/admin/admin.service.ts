import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { AdminAudit } from '../audit/admin-audit.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(DriverProfile) private driverRepo: Repository<DriverProfile>,
    @InjectRepository(AdminAudit) private auditRepo: Repository<AdminAudit>,
  ) {}

  async listUsers() {
    return this.usersRepo.find({
      where: { deletedAt: null },
      order: { createdAt: 'DESC' },
    });
  }

  async getUserDetails(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId }});
    if (!user) throw new NotFoundException('User not found');

    let driverProfile = null;
    if (user.role === 'DRIVER') {
      driverProfile = await this.driverRepo.findOne({
        where: { user: { id: user.id } },
      });
    }

    return { user, driverProfile };
  }

  async suspendUser(targetUserId: string, adminUser: User, reason?: string) {
    const user = await this.usersRepo.findOne({ where: { id: targetUserId }});
    if (!user) throw new NotFoundException('User not found');

    user.isSuspended = true;
    user.suspensionReason = reason ?? 'Violation of terms';
    await this.usersRepo.save(user);

    await this.auditRepo.save({
      targetUser: user,
      performedBy: adminUser,
      action: 'SUSPEND_USER',
      reason,
    });

    return user;
  }

  async reinstateUser(targetUserId: string, adminUser: User) {
    const user = await this.usersRepo.findOne({ where: { id: targetUserId }});
    if (!user) throw new NotFoundException('User not found');

    user.isSuspended = false;
    user.suspensionReason = null;
    await this.usersRepo.save(user);

    await this.auditRepo.save({
      targetUser: user,
      performedBy: adminUser,
      action: 'REINSTATE_USER',
      reason: null,
    });

    return user;
  }
}
