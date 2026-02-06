import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, IsNull } from 'typeorm';
import { UserEntity } from '../users/user.entity';
import { UpdateProfileDto, PrivacySettingsDto } from './dto/profile.dto';

@Injectable()
export class ProfileService {
  constructor(
    @InjectRepository(UserEntity) private usersRepo: Repository<UserEntity>,
  ) {}

  async getProfile(userId: string) {
    const user = await this.usersRepo.findOne({
      where: { id: userId, deletedAt: IsNull() },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.getProfile(userId);
    Object.assign(user, dto);
    return this.usersRepo.save(user);
  }

  async updatePrivacy(userId: string, dto: PrivacySettingsDto) {
    const user = await this.getProfile(userId);
    Object.assign(user, dto);
    return this.usersRepo.save(user);
  }

  async deactivateAccount(userId: string) {
    const user = await this.getProfile(userId);
    user.isActive = false;
    return this.usersRepo.save(user);
  }

  async deleteAccount(userId: string) {
    const user = await this.getProfile(userId);
    user.deletedAt = new Date();
    user.isActive = false;
    return this.usersRepo.save(user);
  }

  async exportUserData(userId: string) {
    const user = await this.getProfile(userId);

    return {
      profile: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        createdAt: user.createdAt,
      },
      privacy: {
        shareLocation: user.shareLocation,
        shareRideHistory: user.shareRideHistory,
      },
    };
  }
}
