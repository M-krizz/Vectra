import { IsString, IsOptional, ValidateIf, IsEmail } from "class-validator";

export class CreateRiderDto {
  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;

  @IsString()
  fullName!: string;

  @IsOptional()
  @IsString()
  password?: string;
}

export class CreateDriverDto {
  @ValidateIf((o) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o) => !o.email)
  @IsString()
  phone?: string;

  @IsString()
  fullName!: string;

  @IsOptional()
  @IsString()
  password?: string;

  @IsString()
  licenseNumber!: string;

  @IsOptional()
  @IsString()
  licenseState?: string;
}
