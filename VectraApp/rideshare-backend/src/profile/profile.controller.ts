import { Controller, Get, Patch, Post, Delete, Body, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ProfileService } from './profile.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { PrivacySettingsDto } from './dto/privacy-settings.dto';

@Controller('profile')
@UseGuards(JwtAuthGuard)
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get('me')
  async getMyProfile(@Req() req: any) {
    return this.profileService.getProfile(req.user.id);
  }

  @Patch('me')
  async updateProfile(@Req() req: any, @Body() dto: UpdateProfileDto) {
    return this.profileService.updateProfile(req.user.id, dto);
  }

  @Patch('privacy')
  async updatePrivacy(@Req() req: any, @Body() dto: PrivacySettingsDto) {
    return this.profileService.updatePrivacy(req.user.id, dto);
  }

  @Post('deactivate')
  async deactivate(@Req() req: any) {
    await this.profileService.deactivateAccount(req.user.id);
    return { status: 'deactivated' };
  }

  @Delete('delete')
  async deleteAccount(@Req() req: any) {
    await this.profileService.deleteAccount(req.user.id);
    return { status: 'deleted' };
  }

  @Get('export')
  async exportMyData(@Req() req: any) {
    return this.profileService.exportUserData(req.user.id);
  }
}
