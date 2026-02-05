import {
  Controller,
  Get,
  Post,
  Body,
  Param,
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
}
