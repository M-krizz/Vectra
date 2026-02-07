import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { AdminAudit } from '../audit/admin-audit.entity';
import { RideRequest, RideStatus } from '../rides/entities/ride-request.entity';
import Redis from 'ioredis';

@Injectable()
export class AdminService {
  private redis: Redis;

  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(DriverProfile) private driverRepo: Repository<DriverProfile>,
    @InjectRepository(AdminAudit) private auditRepo: Repository<AdminAudit>,
    @InjectRepository(RideRequest) private rideRepo: Repository<RideRequest>,
  ) {
    this.redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
  }

  async listUsers() {
    return this.usersRepo.find({
      where: { deletedAt: null },
      order: { createdAt: 'DESC' },
    });
  }

  async getUserDetails(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
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
    const user = await this.usersRepo.findOne({ where: { id: targetUserId } });
    if (!user) throw new NotFoundException('User not found');

    user.isSuspended = true;
    user.suspensionReason = reason ?? 'Violation of terms';
    await this.usersRepo.save(user);

    await this.auditRepo.save({
      targetUser: user,
      performedBy: adminUser,
      action: 'SUSPEND_USER',
      reason,
    } as any);

    return user;
  }

  async reinstateUser(targetUserId: string, adminUser: User) {
    const user = await this.usersRepo.findOne({ where: { id: targetUserId } });
    if (!user) throw new NotFoundException('User not found');

    user.isSuspended = false;
    user.suspensionReason = null;
    await this.usersRepo.save(user);

    await this.auditRepo.save({
      targetUser: user,
      performedBy: adminUser,
      action: 'REINSTATE_USER',
      reason: null,
    } as any);

    return user;
  }

  async getFleetStatus() {
    const drivers = await this.driverRepo.find({ relations: ['user'] });
    const fleet = [];

    for (const driver of drivers) {
      const presenceKey = `driver:presence:${driver.user.id}`;
      const locationKey = `driver:location:${driver.user.id}`;

      const isOnline = !!(await this.redis.get(presenceKey));
      const location = await this.redis.get(locationKey);

      const activeRide = await this.rideRepo.findOne({
        where: [
          { driver: { id: driver.user.id }, status: RideStatus.ACCEPTED },
          { driver: { id: driver.user.id }, status: RideStatus.EN_ROUTE },
          { driver: { id: driver.user.id }, status: RideStatus.ARRIVED },
        ],
      });

      let status = 'OFFLINE';
      if (isOnline) {
        status = activeRide ? 'BUSY' : 'IDLE';
      }

      fleet.push({
        driverId: driver.user.id,
        fullName: driver.user.fullName,
        status,
        location: location ? JSON.parse(location) : null,
        activeRideId: activeRide?.id || null,
      });
    }

    return fleet;
  }

  async getSystemCounters() {
    const activeRides = await this.rideRepo.count({
      where: { status: RideStatus.PENDING },
    });

    const onlineDriversKeys = await this.redis.keys('driver:presence:*');
    const onlineDrivers = onlineDriversKeys.length;

    return {
      activeRides,
      onlineDrivers,
      supplyDemandGap: onlineDrivers - activeRides,
    };
  }
}
