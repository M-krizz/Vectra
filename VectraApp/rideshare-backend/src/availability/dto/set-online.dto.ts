import { IsBoolean, IsOptional } from 'class-validator';

export class SetOnlineDto {
  @IsBoolean()
  online: boolean;

  // optional: device info (android / ios) for session tracking
  @IsOptional()
  deviceInfo?: string;
}
