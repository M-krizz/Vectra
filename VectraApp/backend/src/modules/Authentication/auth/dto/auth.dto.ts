import {
  IsString,
  IsOptional,
  IsNotEmpty,
  IsIn,
} from 'class-validator';

export class RequestOtpDto {
  @IsIn(['phone', 'email'])
  channel!: 'phone' | 'email';

  @IsString()
  @IsNotEmpty()
  identifier!: string;
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  identifier!: string;

  @IsString()
  @IsNotEmpty()
  code!: string;
}

export class CompleteProfileDto {
  @IsString()
  @IsNotEmpty()
  fullName!: string;
}

export class RefreshDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}
