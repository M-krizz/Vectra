import { Controller, Get, Post, Body, Query, UseGuards, Req, Put } from '@nestjs/common';
import { DriversService } from './drivers.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UserEntity } from '../users/user.entity';
import { IsNumber, Min, Max } from 'class-validator';

class LocationDto {
    @IsNumber()
    @Min(-90)
    @Max(90)
    lat!: number;

    @IsNumber()
    @Min(-180)
    @Max(180)
    lng!: number;
}

@Controller('drivers')
@UseGuards(JwtAuthGuard)
export class DriversController {
    constructor(private readonly driversService: DriversService) { }

    @Get('nearby-requests')
    async getNearbyRequests(
        @Req() req: any,
        @Query('lat') lat: number,
        @Query('lng') lng: number
    ) {
        const user = req.user as UserEntity;
        // In a real app, we might verify user.role === 'DRIVER'
        return await this.driversService.getNearbyRequests(user.id, Number(lat), Number(lng));
    }

    @Put('location')
    async updateLocation(@Req() req: any, @Body() dto: LocationDto) {
        const user = req.user as UserEntity;
        await this.driversService.updateLocation(user.id, dto.lat, dto.lng);
        return { success: true };
    }
}
