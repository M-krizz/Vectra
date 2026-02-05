import { IsNotEmpty, IsNumber } from 'class-validator';

export class UpdateTripLocationDto {
  @IsNotEmpty()
  @IsNumber()
  lat!: number;

  @IsNotEmpty()
  @IsNumber()
  lng!: number;
}
