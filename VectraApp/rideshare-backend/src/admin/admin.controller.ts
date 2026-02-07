import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../rbac/permissions.guard';
import { Permissions } from '../rbac/permissions.decorator';
import { AdminService } from './admin.service';
import { SuspendUserDto } from './dto/suspend-user.dto';

@Controller('admin')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) { }

  @Permissions('user:manage')
  @Get('users')
  async listUsers() {
    return this.adminService.listUsers();
  }

  @Permissions('user:manage')
  @Get('users/:id')
  async getUser(@Param('id') id: string) {
    return this.adminService.getUserDetails(id);
  }

  @Permissions('user:manage')
  @Post('users/:id/suspend')
  async suspend(
    @Param('id') id: string,
    @Body() dto: SuspendUserDto,
    @Req() req: any,
  ) {
    return this.adminService.suspendUser(id, req.user, dto.reason);
  }

  @Permissions('user:manage')
  @Post('users/:id/reinstate')
  async reinstate(@Param('id') id: string, @Req() req: any) {
    return this.adminService.reinstateUser(id, req.user);
  }

  @Permissions('fleet:view')
  @Get('fleet/status')
  async getFleetStatus() {
    return this.adminService.getFleetStatus();
  }

  @Permissions('fleet:view')
  @Get('fleet/counters')
  async getSystemCounters() {
    return this.adminService.getSystemCounters();
  }
}
