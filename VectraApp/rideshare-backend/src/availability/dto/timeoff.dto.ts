import { IsISO8601, IsString, IsOptional } from 'class-validator';

export class TimeOffDto {
  @IsISO8601()
  startAt: string;

  @IsISO8601()
  endAt: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
