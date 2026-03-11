import { Controller, Get, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { RolesGuard } from '../Authentication/common/roles.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { UserRole } from '../Authentication/users/user.entity';

@Controller('api/v1/admin/analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.COMMUNITY_ADMIN)
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('stats')
  getDashboardStats() {
    return this.analyticsService.getDashboardStats();
  }

  @Get('trends/revenue')
  getRevenueTrend() {
    return this.analyticsService.getRevenueTrend();
  }

  @Get('trends/trips')
  getTripTrend() {
    return this.analyticsService.getTripTrend();
  }
}
