import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateRideRequestDto {
    @IsNumber()
    @IsNotEmpty()
    pickupLat!: number;

    @IsNumber()
    @IsNotEmpty()
    pickupLng!: number;

    @IsNumber()
    @IsNotEmpty()
    dropoffLat!: number;

    @IsNumber()
    @IsNotEmpty()
    dropoffLng!: number;

    @IsString()
    @IsOptional()
    pickupAddress?: string;

    @IsString()
    @IsOptional()
    dropoffAddress?: string;
}
