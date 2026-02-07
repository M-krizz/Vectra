import { Controller, Post, Body, Get, Query, UseGuards, Param, Req } from '@nestjs/common';
import { RidesService } from './rides.service';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { RolesGuard } from '../common/roles.gaurd';
import { Roles } from '../common/roles.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('rides')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RidesController {
    constructor(private readonly ridesService: RidesService) { }

    @Post('request')
    @Roles('RIDER')
    async createRequest(@Req() req: any, @Body() dto: CreateRideRequestDto) {
        return this.ridesService.createRequest(req.user.id, dto);
    }

    @Get('nearby')
    @Roles('DRIVER')
    async getNearbyRequests(
        @Query('lat') lat: number,
        @Query('lng') lng: number,
        @Query('radius') radius?: number,
    ) {
        return this.ridesService.findNearbyRequests(Number(lat), Number(lng), radius ? Number(radius) : 5000);
    }

    @Get(':id')
    async getRideDetails(@Param('id') id: string) {
        return this.ridesService.getRideDetails(id);
    }
}
