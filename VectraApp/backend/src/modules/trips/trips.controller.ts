import { Controller, Get, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { TripsService } from './trips.service';
import { UpdateTripLocationDto } from './dto/update-trip-location.dto';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { UserRole } from '../Authentication/users/user.entity';
import { TripStatus } from './trip.entity';

@Controller('api/v1/trips')
@UseGuards(JwtAuthGuard)
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Get(':id')
  async getTrip(@Param('id') id: string) {
    return this.tripsService.getTrip(id);
  }

  @Patch(':id/location')
  @Roles(UserRole.DRIVER)
  async updateLocation(
    @Param('id') id: string,
    @Body() dto: UpdateTripLocationDto,
  ) {
    return this.tripsService.updateDriverLocation(id, dto.lat, dto.lng);
  }

  @Patch(':id/start')
  @Roles(UserRole.DRIVER)
  async startTrip(@Param('id') id: string) {
    return this.tripsService.updateTripStatus(id, TripStatus.IN_PROGRESS);
  }

  @Patch(':id/complete')
  @Roles(UserRole.DRIVER)
  async completeTrip(@Param('id') id: string) {
    return this.tripsService.updateTripStatus(id, TripStatus.COMPLETED);
  }

  @Patch(':id/cancel')
  @Roles(UserRole.DRIVER)
  async cancelTrip(@Param('id') id: string) {
    return this.tripsService.updateTripStatus(id, TripStatus.CANCELLED);
  }
}
