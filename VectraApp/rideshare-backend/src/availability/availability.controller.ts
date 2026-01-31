import { Controller, Post, Body, UseGuards, Req, Get, Param, Delete } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AvailabilityService } from './availability.service';
import { SetOnlineDto } from './dto/set-online.dto';
import { HeartbeatDto } from './dto/heartbeat.dto';
import { WeeklyScheduleDto } from './dto/weekly-schedule.dto';
import { TimeOffDto } from './dto/timeoff.dto';

/**
 * Mobile endpoints:
 * - POST /availability/online        { online: true }
 * - POST /availability/heartbeat     no body or deviceInfo
 * - POST /availability/schedule      { dayOfWeek, windows }
 * - GET  /availability/schedule      returns grouped weekly schedules
 * - POST /availability/timeoff       { startAt, endAt, reason }
 * - GET  /availability/timeoff       list timeoffs
 * - DELETE /availability/timeoff/:id remove
 * - GET /availability/is-available   optional query? simple endpoint to check current availability
 */
@Controller('availability')
@UseGuards(JwtAuthGuard)
export class AvailabilityController {
  constructor(private readonly svc: AvailabilityService) {}

  @Post('online')
  async setOnline(@Req() req: any, @Body() body: SetOnlineDto) {
    return this.svc.setOnline(req.user.id, body.online, body.deviceInfo);
  }

  @Post('heartbeat')
  async heartbeat(@Req() req: any, @Body() body: HeartbeatDto) {
    return this.svc.heartbeat(req.user.id, body?.deviceInfo);
  }

  @Post('schedule')
  async setSchedule(@Req() req: any, @Body() dto: WeeklyScheduleDto) {
    return this.svc.setWeeklySchedule(req.user.id, dto.dayOfWeek, dto.windows);
  }

  @Get('schedule')
  async getSchedule(@Req() req: any) {
    return this.svc.getWeeklySchedules(req.user.id);
  }

  @Post('timeoff')
  async addTimeOff(@Req() req: any, @Body() dto: TimeOffDto) {
    return this.svc.addTimeOff(req.user.id, dto.startAt, dto.endAt, dto.reason);
  }

  @Get('timeoff')
  async listTimeOff(@Req() req: any) {
    return this.svc.listTimeOffs(req.user.id);
  }

  @Delete('timeoff/:id')
  async removeTimeOff(@Req() req: any, @Param('id') id: string) {
    return this.svc.removeTimeOff(req.user.id, id);
  }

  @Get('is-available')
  async isAvailable(@Req() req: any) {
    return this.svc.isDriverAvailableAt(req.user.id, new Date());
  }
}
