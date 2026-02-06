import { IsNumber, IsString, IsOptional, IsEnum, Min, Max } from 'class-validator';
import { RideType } from '../ride-request.entity';

export class CreateRideRequestDto {
    @IsNumber()
    @Min(-90)
    @Max(90)
    pickupLat!: number;

    @IsNumber()
    @Min(-180)
    @Max(180)
    pickupLng!: number;

    @IsOptional()
    @IsString()
    pickupAddress?: string;

    @IsNumber()
    @Min(-90)
    @Max(90)
    dropLat!: number;

    @IsNumber()
    @Min(-180)
    @Max(180)
    dropLng!: number;

    @IsOptional()
    @IsString()
    dropAddress?: string;

    @IsOptional()
    @IsEnum(RideType)
    rideType?: RideType;
}
