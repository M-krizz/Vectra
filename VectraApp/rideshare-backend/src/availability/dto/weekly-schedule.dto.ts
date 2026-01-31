import { IsInt, Min, Max, IsString, Matches, IsArray, ValidateNested, ArrayNotEmpty } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Single time window DTO
 */
export class TimeWindowDto {
  @IsString()
  @Matches(/^[0-2]\d:[0-5]\d$/, { message: 'startTime must be HH:MM' })
  startTime: string;

  @IsString()
  @Matches(/^[0-2]\d:[0-5]\d$/, { message: 'endTime must be HH:MM' })
  endTime: string;
}

/**
 * Weekly schedule payload:
 * { dayOfWeek: 1, windows: [{startTime:"08:00", endTime:"12:00"}, ...] }
 */
export class WeeklyScheduleDto {
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek: number;

  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => TimeWindowDto)
  windows: TimeWindowDto[];
}
