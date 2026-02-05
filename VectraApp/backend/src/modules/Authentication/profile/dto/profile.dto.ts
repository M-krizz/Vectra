import {
  IsString,
  IsOptional,
  IsEmail,
  IsArray,
  ValidateNested,
  IsNumber,
} from 'class-validator';
import { Type } from 'class-transformer';

class PreferredLocationDto {
  @IsString()
  name!: string;

  @IsNumber()
  lat!: number;

  @IsNumber()
  lng!: number;

  @IsOptional()
  @IsString()
  address?: string;
}

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  profileImageKey?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PreferredLocationDto)
  preferredLocations?: PreferredLocationDto[];
}

export class PrivacySettingsDto {
  @IsOptional()
  shareLocation?: boolean;

  @IsOptional()
  shareRideHistory?: boolean;
}
