import {
  IsNotEmpty,
  IsEnum,
  IsString,
  ValidateNested,
  IsOptional,
} from 'class-validator';
import { Type } from 'class-transformer';
import { RideType } from '../ride-request.entity';

class GeoPointDto {
  @IsNotEmpty()
  type = 'Point' as const;

  @IsNotEmpty()
  coordinates!: number[]; // [longitude, latitude]
}

export class CreateRideRequestDto {
  @IsNotEmpty()
  @ValidateNested()
  @Type(() => GeoPointDto)
  pickupPoint!: GeoPointDto;

  @IsNotEmpty()
  @ValidateNested()
  @Type(() => GeoPointDto)
  dropPoint!: GeoPointDto;

  @IsOptional()
  @IsString()
  pickupAddress?: string;

  @IsOptional()
  @IsString()
  dropAddress?: string;

  @IsNotEmpty()
  @IsEnum(RideType)
  rideType!: RideType;
}
