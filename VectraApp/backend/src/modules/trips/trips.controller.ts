import { Controller, Get, Patch, Post, Param, Body, UseGuards, Req } from '@nestjs/common';
import { TripsService } from './trips.service';
import { TripOtpService } from './trip-otp.service';
import { UpdateTripLocationDto } from './dto/update-trip-location.dto';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { RolesGuard } from '../Authentication/common/roles.guard';
import { UserRole } from '../Authentication/users/user.entity';
import { TripStatus } from './trip.entity';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';
import { IsArray, IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

class UpdateTripStatusDto {
  @IsEnum(TripStatus)
  status!: TripStatus;
}

class SubmitTripRatingDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  feedback?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}

@Controller('api/v1/trips')
@UseGuards(JwtAuthGuard)
export class TripsController {
  constructor(
    private readonly tripsService: TripsService,
    private readonly tripOtpService: TripOtpService,
  ) { }

  @Get()
  async getUserTrips(@Req() req: AuthenticatedRequest) {
    return this.tripsService.getUserTrips(req.user.userId, req.user.role);
  }

  @Get(':id')
  async getTrip(@Param('id') id: string) {
    return this.tripsService.getTrip(id);
  }

  /**
   * PATCH /api/v1/trips/:id/status
   * Driver or Admin updates trip lifecycle status.
   */
  @Patch(':id/status')
  @Roles(UserRole.DRIVER, UserRole.ADMIN)
  @UseGuards(RolesGuard)
  async updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateTripStatusDto,
  ) {
    return this.tripsService.updateTripStatus(id, dto.status);
  }

  @Patch(':id/location')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  async updateLocation(
    @Param('id') id: string,
    @Body() dto: UpdateTripLocationDto,
  ) {
    return this.tripsService.updateDriverLocation(id, dto.lat, dto.lng);
  }

  /**
   * GET /api/v1/trips/:id/fare
   * Returns the final fare receipt for a completed trip.
   */
  @Get(':id/fare')
  async getTripFare(@Param('id') id: string) {
    return this.tripsService.getTripFare(id);
  }

  /**
   * POST /api/v1/trips/:id/otp/generate
   * Called when driver arrives. Generates OTP and sends it to the rider via WebSocket.
   */
  @Post(':id/otp/generate')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  async generateOtp(
    @Param('id') id: string,
    @Body() body: { riderId: string },
  ) {
    return { otp: await this.tripOtpService.generateOtp(id, body.riderId) };
  }

  /**
   * POST /api/v1/trips/:id/otp/verify
   * Driver submits the OTP received from rider to unlock trip start.
   */
  @Post(':id/otp/verify')
  @Roles(UserRole.DRIVER)
  @UseGuards(RolesGuard)
  async verifyOtp(
    @Param('id') id: string,
    @Body() body: { riderId: string; otp: string },
  ) {
    const ok = await this.tripOtpService.verifyOtp(id, body.riderId, body.otp);
    return { success: ok };
  }

  /**
   * POST /api/v1/trips/:id/rating
   * Rider submits post-trip rating and optional feedback.
   */
  @Post(':id/rating')
  @Roles(UserRole.RIDER)
  @UseGuards(RolesGuard)
  async submitRating(
    @Param('id') id: string,
    @Req() req: AuthenticatedRequest,
    @Body() dto: SubmitTripRatingDto,
  ) {
    return this.tripsService.submitTripRating(id, req.user.userId, dto);
  }
}
