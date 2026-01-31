import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { CreateRiderDto } from './dto/create-rider.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  private readonly SALT_ROUNDS = 12; // per requirements (bcrypt cost factor = 12)

  constructor(
    @InjectRepository(User)
    private usersRepo: Repository<User>,
  ) {}

  async createRider(dto: CreateRiderDto) {
    // Duplicate prevention: check email OR phone collisions
    if (dto.email) {
      const existing = await this.usersRepo.findOne({ where: { email: dto.email } });
      if (existing) {
        throw new ConflictException('Account with this email already exists');
      }
    }
    if (dto.phone) {
      const existing = await this.usersRepo.findOne({ where: { phone: dto.phone } });
      if (existing) {
        throw new ConflictException('Account with this phone already exists');
      }
    }

    const user = new User();
    user.email = dto.email ?? null;
    user.phone = dto.phone ?? null;
    user.fullName = dto.fullName;
    user.preferredLocations = dto.preferredLocations ?? [];
    user.role = 'RIDER';
    user.isVerified = false;

    if (dto.password) {
      const hash = await bcrypt.hash(dto.password, this.SALT_ROUNDS);
      user.passwordHash = hash;
    } else {
      user.passwordHash = null;
    }

    const saved = await this.usersRepo.save(user);

    // return sanitized user object
    const { passwordHash, ...sanitized } = saved as any;
    return sanitized as User;
  }

  // helper: find by id
  async findById(id: string) {
    return await this.usersRepo.findOne({ where: { id } });
  }

  // helper: find by email/phone
  async findByEmailOrPhone(email?: string, phone?: string) {
    if (email) {
      const u = await this.usersRepo.findOne({ where: { email } });
      if (u) return u;
    }
    if (phone) {
      const u = await this.usersRepo.findOne({ where: { phone } });
      if (u) return u;
    }
    return null;
  }
}
