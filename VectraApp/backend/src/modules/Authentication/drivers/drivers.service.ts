import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriverProfileEntity, DriverStatus } from './driver-profile.entity';
import { VehicleEntity } from './vehicle.entity';
import { UserEntity } from '../users/user.entity';

@Injectable()
export class DriversService {
  constructor(
    @InjectRepository(DriverProfileEntity)
    private profileRepo: Repository<DriverProfileEntity>,
    @InjectRepository(VehicleEntity)
    private vehicleRepo: Repository<VehicleEntity>,
    @InjectRepository(UserEntity) private usersRepo: Repository<UserEntity>,
  ) {}

  async getProfile(userId: string) {
    const profile = await this.profileRepo.findOne({
      where: { userId },
      relations: ['user'],
    });
    if (!profile) throw new NotFoundException('Driver profile not found');
    return profile;
  }

  async updateLicense(
    userId: string,
    licenseNumber: string,
    licenseState?: string,
  ) {
    const profile = await this.getProfile(userId);
    profile.licenseNumber = licenseNumber;
    if (licenseState) profile.licenseState = licenseState;
    profile.status = DriverStatus.DOCUMENTS_SUBMITTED;
    return this.profileRepo.save(profile);
  }

  async setOnlineStatus(userId: string, online: boolean) {
    const profile = await this.getProfile(userId);
    if (profile.status !== DriverStatus.VERIFIED) {
      throw new ForbiddenException('Driver not verified');
    }
    profile.onlineStatus = online;
    return this.profileRepo.save(profile);
  }

  async getVehicles(userId: string) {
    return this.vehicleRepo.find({
      where: { driverUserId: userId, isActive: true },
    });
  }

  async addVehicle(userId: string, vehicleData: Partial<VehicleEntity>) {
    const vehicle = this.vehicleRepo.create({
      ...vehicleData,
      driverUserId: userId,
    });
    return this.vehicleRepo.save(vehicle);
  }

  async verifyDriver(adminUserId: string, driverProfileId: string) {
    const profile = await this.profileRepo.findOne({
      where: { id: driverProfileId },
    });
    if (!profile) throw new NotFoundException('Driver profile not found');

    profile.status = DriverStatus.VERIFIED;
    return this.profileRepo.save(profile);
  }

  async suspendDriver(
    adminUserId: string,
    driverProfileId: string,
    reason?: string,
  ) {
    const profile = await this.profileRepo.findOne({
      where: { id: driverProfileId },
      relations: ['user'],
    });
    if (!profile) throw new NotFoundException('Driver profile not found');

    profile.status = DriverStatus.SUSPENDED;
    profile.meta = { ...profile.meta, suspensionReason: reason };
    return this.profileRepo.save(profile);
  }
}
