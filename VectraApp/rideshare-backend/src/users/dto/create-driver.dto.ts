import { IsEmail, IsOptional, MaxLength, Matches, Validate, IsArray, ArrayNotEmpty } from 'class-validator';
import { IsEmailOrPhone } from '../../common/validator/email-or-phone.validator';
import { IsLicenseNumber } from '../../common/validator/license-number.validator';

export class CreateDriverDto {
  @IsOptional()
  @IsEmail({}, { message: 'Invalid email' })
  email?: string;

  @IsOptional()
  @Matches(/^\+?[1-9]\d{6,14}$/, {
    message: 'Phone must be in E.164-ish format',
  })
  phone?: string;

  @MaxLength(150)
  fullName: string;

  @IsLicenseNumber({ message: 'Invalid license number format' })
  licenseNumber: string;

  @MaxLength(32)
  licenseState: string;

  // vehicle details - require at least one vehicle
  @IsArray()
  @ArrayNotEmpty()
  vehicles: {
    model: string;
    plateNumber: string;
    seatingCapacity: number;
    vehicleType: 'SEDAN'|'SUV'|'EV'|'BIKE';
  }[];

  @Validate(IsEmailOrPhone)
  _emailOrPhoneIsPresent: any;
}
