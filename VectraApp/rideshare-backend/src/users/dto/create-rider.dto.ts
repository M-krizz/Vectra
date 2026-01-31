import { IsEmail, IsOptional, Length, Matches, MaxLength, Validate } from 'class-validator';
import { IsEmailOrPhone } from '../../common/validators/email-or-phone.validator';

export class CreateRiderDto {
  @IsOptional()
  @IsEmail({}, { message: 'Invalid email address' })
  email?: string;

  @IsOptional()
  @Matches(/^\+?[1-9]\d{6,14}$/, {
    message: 'Phone must be in E.164-ish format, e.g. +919876543210 or 9876543210',
  })
  phone?: string;

  @MaxLength(150)
  fullName: string;

  // optional password — hashed if present (bcrypt with cost=12)
  @IsOptional()
  @Length(8, 128, { message: 'Password must be at least 8 characters' })
  password?: string;

  // location preferences array — mobile app will send named saved locations
  @IsOptional()
  preferredLocations?: { name: string; lat: number; lng: number }[];
  
  // apply custom decorator to ensure at least email or phone is present
  @Validate(IsEmailOrPhone)
  _emailOrPhoneIsPresent: any;
}
