import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { DriversService } from './drivers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { UserRole } from '../users/user.entity';
import { VehicleEntity } from './vehicle.entity';

@Controller('api/v1/drivers')
@UseGuards(JwtAuthGuard)
export class DriversController {
  constructor(private readonly driversService: DriversService) {}

  @Get('profile')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  getProfile(@Req() req: { user: { userId: string } }) {
    return this.driversService.getProfile(req.user.userId);
  }

  @Patch('license')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  updateLicense(
    @Req() req: { user: { userId: string } },
    @Body() dto: { licenseNumber: string; licenseState?: string },
  ) {
    return this.driversService.updateLicense(
      req.user.userId,
      dto.licenseNumber,
      dto.licenseState,
    );
  }

  @Post('online')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  setOnline(
    @Req() req: { user: { userId: string } },
    @Body() dto: { online: boolean },
  ) {
    return this.driversService.setOnlineStatus(req.user.userId, dto.online);
  }

  @Get('vehicles')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  getVehicles(@Req() req: { user: { userId: string } }) {
    return this.driversService.getVehicles(req.user.userId);
  }

  @Post('vehicles')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  addVehicle(
    @Req() req: { user: { userId: string } },
    @Body() dto: Partial<VehicleEntity>,
  ) {
    return this.driversService.addVehicle(req.user.userId, dto);
  }
}
