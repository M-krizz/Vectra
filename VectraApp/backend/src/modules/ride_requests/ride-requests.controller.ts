import {
  Controller,
  Post,
  Body,
  UseGuards,
  Req,
  Get,
  Param,
  Patch,
} from '@nestjs/common';
import { RideRequestsService } from './ride-requests.service';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { UserRole } from '../Authentication/users/user.entity';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';

@Controller('api/v1/ride-requests')
@UseGuards(JwtAuthGuard)
export class RideRequestsController {
  constructor(private readonly rideRequestsService: RideRequestsService) {}

  @Post()
  @Roles(UserRole.RIDER)
  async createRequest(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateRideRequestDto,
  ) {
    return this.rideRequestsService.createRequest(req.user.userId, dto);
  }

  @Get('current')
  @Roles(UserRole.RIDER)
  async getCurrentRequest(@Req() req: AuthenticatedRequest) {
    return this.rideRequestsService.getActiveRequestForUser(req.user.userId);
  }

  @Patch(':id/cancel')
  @Roles(UserRole.RIDER)
  async cancelRequest(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.rideRequestsService.cancelRequest(id, req.user.userId);
  }
}
