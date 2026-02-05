import {
  IsEmail,
  IsOptional,
  IsString,
  IsNotEmpty,
  ValidateIf,
  IsIn,
} from 'class-validator';

export class RequestOtpDto {
  @IsIn(['phone', 'email'])
  channel!: 'phone' | 'email';

  @IsString()
  @IsNotEmpty()
  identifier!: string;

  @IsOptional()
  @IsIn(['RIDER', 'DRIVER', 'ADMIN'])
  roleHint?: 'RIDER' | 'DRIVER' | 'ADMIN';
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  identifier!: string;

  @IsString()
  @IsNotEmpty()
  code!: string;
}

export class LoginDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @ValidateIf((o: LoginDto) => !o.otp)
  @IsString()
  password?: string;

  @ValidateIf((o: LoginDto) => !o.password)
  @IsString()
  otp?: string;
}

export class RefreshDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}
