import { IsIn, IsInt, Max, Min, IsString } from 'class-validator';

export class PresignRequestDto {
  @IsIn(['DRIVER_LICENSE','VEHICLE_REG','PROFILE_PHOTO'])
  docType: 'DRIVER_LICENSE'|'VEHICLE_REG'|'PROFILE_PHOTO';

  @IsString()
  originalName: string;

  @IsInt()
  @Min(1)
  @Max(5 * 1024 * 1024) // max 5MB
  size: number;

  @IsString()
  mimeType: string;
}
