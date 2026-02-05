import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { UserEntity, UserRole } from './user.entity';
import { CreateRiderDto, CreateDriverDto } from './dto/users.dto';
import {
  DriverProfileEntity,
  DriverStatus,
} from '../drivers/driver-profile.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(UserEntity) private usersRepo: Repository<UserEntity>,
    @InjectRepository(DriverProfileEntity)
    private driverProfileRepo: Repository<DriverProfileEntity>,
  ) {}

  async findById(id: string) {
    return this.usersRepo.findOne({ where: { id } });
  }

  async findByEmail(email: string) {
    return this.usersRepo.findOne({ where: { email } });
  }

  async findByPhone(phone: string) {
    return this.usersRepo.findOne({ where: { phone } });
  }

  async createRider(dto: CreateRiderDto) {
    const existing = await this.usersRepo.findOne({
      where: [{ email: dto.email }, { phone: dto.phone }],
    });
    if (existing) throw new ConflictException('User already exists');

    const user = this.usersRepo.create({
      email: dto.email || null,
      phone: dto.phone || null,
      fullName: dto.fullName,
      role: UserRole.RIDER,
      passwordHash: dto.password ? await bcrypt.hash(dto.password, 12) : null,
    });

    return this.usersRepo.save(user);
  }

  async createDriver(dto: CreateDriverDto) {
    const existing = await this.usersRepo.findOne({
      where: [{ email: dto.email }, { phone: dto.phone }],
    });
    if (existing) throw new ConflictException('User already exists');

    const user = this.usersRepo.create({
      email: dto.email || null,
      phone: dto.phone || null,
      fullName: dto.fullName,
      role: UserRole.DRIVER,
      passwordHash: dto.password ? await bcrypt.hash(dto.password, 12) : null,
    });

    const savedUser = await this.usersRepo.save(user);

    // Create driver profile
    const profile = this.driverProfileRepo.create({
      userId: savedUser.id,
      licenseNumber: dto.licenseNumber,
      licenseState: dto.licenseState || null,
      status: DriverStatus.PENDING_VERIFICATION,
    });

    await this.driverProfileRepo.save(profile);

    return savedUser;
  }
}
