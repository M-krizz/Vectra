import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { PrivacySettingsDto } from './dto/privacy-settings.dto';

@Injectable()
export class ProfileService {
  constructor(
    @InjectRepository(User)
    private usersRepo: Repository<User>,
  ) {}

  async getProfile(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId, deletedAt: null }});
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

    // IMPORTANT: Only export user-owned data
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
