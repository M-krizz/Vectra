import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ProfileService } from './profile.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateProfileDto, PrivacySettingsDto } from './dto/profile.dto';

@Controller('api/v1/profile')
@UseGuards(JwtAuthGuard)
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get()
  getProfile(@Req() req: { user: { userId: string } }) {
    return this.profileService.getProfile(req.user.userId);
  }

  @Patch()
  updateProfile(
    @Req() req: { user: { userId: string } },
    @Body() dto: UpdateProfileDto,
  ) {
    return this.profileService.updateProfile(req.user.userId, dto);
  }

  @Patch('privacy')
  updatePrivacy(
    @Req() req: { user: { userId: string } },
    @Body() dto: PrivacySettingsDto,
  ) {
    return this.profileService.updatePrivacy(req.user.userId, dto);
  }

  @Post('deactivate')
  deactivateAccount(@Req() req: { user: { userId: string } }) {
    return this.profileService.deactivateAccount(req.user.userId);
  }

  @Delete()
  deleteAccount(@Req() req: { user: { userId: string } }) {
    return this.profileService.deleteAccount(req.user.userId);
  }

  @Get('export')
  exportData(@Req() req: { user: { userId: string } }) {
    return this.profileService.exportUserData(req.user.userId);
  }
}
