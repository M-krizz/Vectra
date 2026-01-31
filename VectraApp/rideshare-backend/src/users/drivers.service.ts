import { Injectable, ConflictException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { User } from './user.entity';
import { DriverProfile, DriverStatus } from './driver-profile.entity';
import { Vehicle } from './vehicle.entity';
import { CreateDriverDto } from './dto/create-driver.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class DriversService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(DriverProfile) private profilesRepo: Repository<DriverProfile>,
    @InjectRepository(Vehicle) private vehicleRepo: Repository<Vehicle>,
    private dataSource: DataSource,
  ) {}

  async registerDriver(dto: CreateDriverDto) {
    // Duplicate checks
    if (dto.email) {
      const e = await this.usersRepo.findOne({ where: { email: dto.email } });
      if (e) throw new ConflictException('Email already in use');
    }
    if (dto.phone) {
      const p = await this.usersRepo.findOne({ where: { phone: dto.phone } });
      if (p) throw new ConflictException('Phone already in use');
    }

    // Transactional create
    return await this.dataSource.transaction(async (manager) => {
      const userRepo = manager.getRepository(User);
      const profileRepo = manager.getRepository(DriverProfile);
      const vehicleRepoTx = manager.getRepository(Vehicle);

      // Create user
      const user = userRepo.create({
        email: dto.email ?? null,
        phone: dto.phone ?? null,
        fullName: dto.fullName,
        role: 'DRIVER',
        isVerified: false,
        preferredLocations: [],
        passwordHash: null,
      });
      const savedUser = await userRepo.save(user);

      // Create driver profile
      const profile = profileRepo.create({
        user: savedUser,
        licenseNumber: dto.licenseNumber,
        licenseState: dto.licenseState,
        status: DriverStatus.PENDING_VERIFICATION,
        meta: {},
      });
      const savedProfile = await profileRepo.save(profile);

      // Create vehicles
      for (const v of dto.vehicles) {
        const vehicle = vehicleRepoTx.create({
          driverProfile: savedProfile,
          model: v.model,
          plateNumber: v.plateNumber,
          seatingCapacity: v.seatingCapacity,
          vehicleType: v.vehicleType,
        });
        await vehicleRepoTx.save(vehicle);
      }

      // Return sanitized result
      const { passwordHash, ...sanitized } = savedUser as any;
      return { user: sanitized, profile: savedProfile };
    });
  }

  async setProfileStatus(driverProfileId: string, status: DriverStatus) {
    const profile = await this.profilesRepo.findOne({ where: { id: driverProfileId }, relations: ['user'] });
    if (!profile) throw new BadRequestException('Profile not found');
    profile.status = status;
    await this.profilesRepo.save(profile);

    if (status === DriverStatus.VERIFIED) {
      // mark user as verified
      profile.user.isVerified = true;
      await this.usersRepo.save(profile.user);
    }
    return profile;
  }
}
