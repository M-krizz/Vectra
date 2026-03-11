import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, IsNull, Repository } from 'typeorm';
import { UserEntity, UserRole } from '../users/user.entity';
import { DriverProfileEntity } from '../drivers/driver-profile.entity';
import { AdminAuditEntity, AdminAction } from './admin-audit.entity';
import { RideRequestEntity } from '../../ride_requests/ride-request.entity';
import { IncidentEntity } from '../../safety/entities/incident.entity';
import { IncidentStatus } from '../../safety/types/incident.types';
import { DriverStatus } from '../drivers/driver-profile.entity';
import { TripEntity } from '../../trips/trip.entity';
import { IncentiveEntity } from '../../incentives/incentive.entity';

export interface AdminDemandPoint {
  time: string;
  trips: number;
}

export interface AdminMetricsOverview {
  activeDrivers: number;
  openSosAlerts: number;
  demandIndex: number;
  avgWaitMinutes: number;
  demandHistory: AdminDemandPoint[];
}

export interface PendingDriverApproval {
  id: string;
  userId: string;
  firstName: string;
  lastName: string;
  licenseNumber: string;
  licenseFileUrl: string | null;
  rcNumber: string;
  rcFileUrl: string | null;
  status: DriverStatus;
}

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(UserEntity) private usersRepo: Repository<UserEntity>,
    @InjectRepository(DriverProfileEntity)
    private driverRepo: Repository<DriverProfileEntity>,
    @InjectRepository(RideRequestEntity)
    private rideRequestRepo: Repository<RideRequestEntity>,
    @InjectRepository(IncidentEntity)
    private incidentRepo: Repository<IncidentEntity>,
    @InjectRepository(AdminAuditEntity)
    private auditRepo: Repository<AdminAuditEntity>,
    @InjectRepository(TripEntity)
    private tripRepo: Repository<TripEntity>,
    @InjectRepository(IncentiveEntity)
    private incentiveRepo: Repository<IncentiveEntity>,
  ) {}

  async getMetricsOverview(): Promise<AdminMetricsOverview> {
    const now = new Date();
    const windowStart = new Date(now.getTime() - 30 * 60 * 1000);
    const historyStepMs = 5 * 60 * 1000;
    const historyBuckets = 12;

    const [activeDrivers, openSosAlerts, recentRequests] = await Promise.all([
      this.driverRepo.count({ where: { onlineStatus: true } }),
      this.incidentRepo.count({ where: { status: IncidentStatus.OPEN } }),
      this.rideRequestRepo.find({
        where: { requestedAt: Between(windowStart, now) },
        select: ['requestedAt'],
      }),
    ]);

    const demandHistory = Array.from({ length: historyBuckets }, (_, index) => {
      const bucketStart = new Date(windowStart.getTime() + index * historyStepMs);
      const bucketEnd = new Date(bucketStart.getTime() + historyStepMs);

      const trips = recentRequests.filter((req) => {
        const ts = new Date(req.requestedAt).getTime();
        return ts >= bucketStart.getTime() && ts < bucketEnd.getTime();
      }).length;

      return {
        time: bucketStart.toLocaleTimeString([], {
          hour: '2-digit',
          minute: '2-digit',
        }),
        trips,
      };
    });

    const latestDemand = demandHistory[demandHistory.length - 1]?.trips ?? 0;

    // Approximate queueing wait using demand-to-driver pressure.
    const pressure = activeDrivers > 0 ? latestDemand / activeDrivers : latestDemand;
    const avgWaitMinutes = Number((2.5 + pressure * 3.2).toFixed(1));

    return {
      activeDrivers,
      openSosAlerts,
      demandIndex: latestDemand,
      avgWaitMinutes,
      demandHistory,
    };
  }

  async listUsers() {
    return this.usersRepo.find({
      where: { deletedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
  }

  async listPendingDrivers(): Promise<PendingDriverApproval[]> {
    const pending = await this.driverRepo.find({
      where: [
        { status: DriverStatus.PENDING_VERIFICATION },
        { status: DriverStatus.DOCUMENTS_SUBMITTED },
        { status: DriverStatus.UNDER_REVIEW },
      ],
      relations: ['user'],
      order: { createdAt: 'ASC' },
    });

    return pending.map((profile) => {
      const fullName = profile.user?.fullName?.trim() || '';
      const [firstName, ...rest] = fullName.split(' ');

      return {
        id: profile.id,
        userId: profile.userId,
        firstName: firstName || 'Driver',
        lastName: rest.join(' '),
        licenseNumber: profile.licenseNumber || '',
        licenseFileUrl: profile.licenseFileUrl,
        rcNumber: profile.meta?.['rcNumber'] as string || '',
        rcFileUrl: profile.rcFileUrl,
        status: profile.status,
      };
    });
  }

  async updateDriverApprovalStatus(
    driverProfileId: string,
    status: 'APPROVED' | 'REJECTED',
    adminUserId: string,
  ) {
    const profile = await this.driverRepo.findOne({
      where: { id: driverProfileId },
    });
    if (!profile) throw new NotFoundException('Driver profile not found');

    const nextStatus =
      status === 'APPROVED' ? DriverStatus.VERIFIED : DriverStatus.SUSPENDED;
    profile.status = nextStatus;
    await this.driverRepo.save(profile);

    await this.auditRepo.save({
      targetUserId: profile.userId,
      performedById: adminUserId,
      action:
        status === 'APPROVED'
          ? AdminAction.APPROVE_DRIVER
          : AdminAction.REJECT_DRIVER,
      reason: null,
      meta: { driverProfileId, status: nextStatus },
    });

    return { success: true, profileId: profile.id, status: nextStatus };
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

  async listAllTrips(status?: string) {
    const qb = this.tripRepo
      .createQueryBuilder('trip')
      .leftJoinAndSelect('trip.driver', 'driver')
      .leftJoinAndSelect('trip.tripRiders', 'rider')
      .orderBy('trip.createdAt', 'DESC')
      .take(200);

    if (status) {
      qb.where('trip.status = :status', { status });
    }

    const trips = await qb.getMany();
    return trips.map((t) => ({
      id: t.id,
      status: t.status,
      vehicleType: t.vehicleType,
      rideType: t.rideType,
      distanceMeters: t.distanceMeters,
      driverName: t.driver?.fullName ?? null,
      driverUserId: t.driverUserId,
      riderCount: t.tripRiders?.length ?? 0,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    }));
  }

  async listAllIncentives() {
    const incentives = await this.incentiveRepo.find({
      relations: ['driver'],
      order: { createdAt: 'DESC' },
      take: 200,
    });
    return incentives.map((inc) => ({
      id: inc.id,
      driverUserId: inc.driverUserId,
      driverName: inc.driver?.fullName ?? null,
      title: inc.title,
      description: inc.description,
      rewardAmount: inc.rewardAmount,
      currentProgress: inc.currentProgress,
      targetProgress: inc.targetProgress,
      isCompleted: inc.isCompleted,
      expiresAt: inc.expiresAt,
      createdAt: inc.createdAt,
    }));
  }
}
