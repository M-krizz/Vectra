import {
  Controller,
  Get,
  Patch,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { UserRole } from '../users/user.entity';
import { SuspendUserDto } from './dto/admin.dto';

@Controller('api/v1/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('users')
  listUsers() {
    return this.adminService.listUsers();
  }

  @Get('users/:userId')
  getUserDetails(@Param('userId') userId: string) {
    return this.adminService.getUserDetails(userId);
  }

  @Get('metrics/overview')
  getMetricsOverview() {
    return this.adminService.getMetricsOverview();
  }

  @Get('drivers/pending')
  listPendingDrivers() {
    return this.adminService.listPendingDrivers();
  }

  @Patch('drivers/:id/status')
  updateDriverStatus(
    @Param('id') id: string,
    @Body() body: { status: 'APPROVED' | 'REJECTED' },
    @Req() req: { user: { userId: string } },
  ) {
    return this.adminService.updateDriverApprovalStatus(
      id,
      body.status,
      req.user.userId,
    );
  }

  @Post('users/suspend')
  suspendUser(
    @Body() dto: SuspendUserDto,
    @Req() req: { user: { userId: string } },
  ) {
    return this.adminService.suspendUser(
      dto.targetUserId,
      req.user.userId,
      dto.reason,
    );
  }

  @Post('users/:userId/reinstate')
  reinstateUser(
    @Param('userId') userId: string,
    @Req() req: { user: { userId: string } },
  ) {
    return this.adminService.reinstateUser(userId, req.user.userId);
  }

  @Get('trips')
  listAllTrips(@Query('status') status?: string) {
    return this.adminService.listAllTrips(status);
  }

  @Get('incentives')
  listAllIncentives() {
    return this.adminService.listAllIncentives();
  }
}
