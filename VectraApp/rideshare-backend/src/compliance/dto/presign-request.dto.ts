import { IsIn, IsInt, IsString, Max, Min } from 'class-validator';

export class PresignRequestDto {
  @IsIn(['DRIVER_LICENSE','VEHICLE_REG','INSURANCE','PROFILE_PHOTO'])
  docType: 'DRIVER_LICENSE'|'VEHICLE_REG'|'INSURANCE'|'PROFILE_PHOTO';

  @IsString()
  originalName: string;

  @IsInt()
  @Min(1)
  @Max(10 * 1024 * 1024) // allow up to 10MB if needed
  size: number;

  @IsString()
  mimeType: string;

  // optional expected expiry (ISO string) provided by user; server may accept or override after verification
  @IsString()
  // keep optional and validated in service
  expiresAt?: string;
}
