import { Controller, Post, Body, UseGuards, Get } from '@nestjs/common';
import { FareService } from './fare.service';
import { VehicleType } from '../ride_requests/ride-request.enums';
import { RideType } from '../ride_requests/ride-request.enums';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { IsEnum, IsNumber, IsOptional, Min } from 'class-validator';

class EstimateFareDto {
    @IsEnum(VehicleType)
    vehicleType!: VehicleType;

    @IsEnum(RideType)
    rideType!: RideType;

    @IsNumber()
    @Min(0)
    distanceMeters!: number;

    @IsNumber()
    @IsOptional()
    demandRatio?: number;
}

@Controller('api/v1/fare')
@UseGuards(JwtAuthGuard)
export class FareController {
    constructor(private readonly fareService: FareService) { }

    /**
     * GET /api/v1/fare/rate-cards
     * Returns published fare cards for driver apps.
     */
    @Get('rate-cards')
    getRateCards() {
        return this.fareService.getRateCards();
    }

    /**
     * POST /api/v1/fare/estimate
     * Returns a fare estimate before a ride is booked.
     */
    @Post('estimate')
    estimate(@Body() dto: EstimateFareDto) {
        return this.fareService.estimate(
            dto.vehicleType,
            dto.rideType,
            dto.distanceMeters,
            dto.demandRatio ?? 0,
        );
    }
}
