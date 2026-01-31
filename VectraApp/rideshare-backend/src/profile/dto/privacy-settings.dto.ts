import { IsBoolean, IsOptional } from 'class-validator';

export class PrivacySettingsDto {
  @IsOptional()
  @IsBoolean()
  shareLocation?: boolean;

  @IsOptional()
  @IsBoolean()
  shareRideHistory?: boolean;
}
