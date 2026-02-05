import { IsString, IsOptional, ValidateIf, IsEmail } from "class-validator";

export class CreateRiderDto {
  @ValidateIf((o: CreateRiderDto) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o: CreateRiderDto) => !o.email)
  @IsString()
  phone?: string;

  @IsString()
  fullName!: string;

  @IsOptional()
  @IsString()
  password?: string;
}

export class CreateDriverDto {
  @ValidateIf((o: CreateDriverDto) => !o.phone)
  @IsEmail()
  email?: string;

  @ValidateIf((o: CreateDriverDto) => !o.email)
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
