import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
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
  ) { }

  async getProfile(userId: string) {
    const profile = await this.profileRepo.findOne({
      where: { userId },
      relations: ['user'],
    });
    if (!profile) throw new NotFoundException('Driver profile not found');
    return profile;
  }

  async uploadDocument(
    userId: string,
    docType: 'LICENSE' | 'RC',
    filename: string,
  ) {
    const profile = await this.getProfile(userId);
    const fileUrl = `/uploads/drivers/${filename}`;

    if (docType === 'LICENSE') {
      profile.licenseFileUrl = fileUrl;
    } else if (docType === 'RC') {
      profile.rcFileUrl = fileUrl;
    }

    // Auto-update status if both are submitted and currently pending
    if (
      profile.licenseFileUrl &&
      profile.rcFileUrl &&
      profile.status === DriverStatus.PENDING_VERIFICATION
    ) {
      profile.status = DriverStatus.DOCUMENTS_SUBMITTED;
    }

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
    const input = vehicleData as Partial<VehicleEntity> & {
      type?: string;
      brand?: string;
      vehicleNumber?: string;
    };

    const plateNumber = (
      input.plateNumber ?? input.vehicleNumber ?? ''
    ).trim().toUpperCase();
    const vehicleType = (input.vehicleType ?? input.type ?? '').trim();

    if (!plateNumber) {
      throw new BadRequestException('plateNumber is required');
    }
    if (!vehicleType) {
      throw new BadRequestException('vehicleType is required');
    }

    const make = input.make ?? input.brand ?? null;
    const seatingCapacity =
      input.seatingCapacity ?? this.getDefaultSeatingCapacity(vehicleType);

    const existingByPlate = await this.vehicleRepo.findOne({
      where: { plateNumber },
    });

    if (existingByPlate && existingByPlate.driverUserId !== userId) {
      throw new ConflictException('Vehicle already registered');
    }

    if (existingByPlate) {
      existingByPlate.vehicleType = vehicleType;
      existingByPlate.make = make;
      existingByPlate.model = input.model ?? existingByPlate.model;
      existingByPlate.year = input.year ?? existingByPlate.year;
      existingByPlate.color = input.color ?? existingByPlate.color;
      existingByPlate.seatingCapacity = seatingCapacity;
      existingByPlate.isActive = input.isActive ?? true;
      return this.vehicleRepo.save(existingByPlate);
    }

    const vehicle = this.vehicleRepo.create({
      driverUserId: userId,
      plateNumber,
      vehicleType,
      make,
      model: input.model ?? null,
      year: input.year ?? null,
      color: input.color ?? null,
      seatingCapacity,
      emissionFactorGPerKm: input.emissionFactorGPerKm ?? null,
      isActive: input.isActive ?? true,
    });
    return this.vehicleRepo.save(vehicle);
  }

  private getDefaultSeatingCapacity(vehicleType: string): number {
    const normalized = vehicleType.trim().toUpperCase();
    if (normalized.includes('BIKE') || normalized.includes('MOTOR')) return 2;
    if (normalized.includes('AUTO') || normalized.includes('RICKSHAW')) {
      return 3;
    }
    if (normalized.includes('SUV') || normalized.includes('VAN')) return 6;
    return 4;
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
