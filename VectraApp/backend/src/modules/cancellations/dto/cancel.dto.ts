import { IsString, IsNotEmpty } from 'class-validator';

export class CancelTripDto {
    @IsString()
    @IsNotEmpty()
    tripId!: string;

    @IsString()
    reason!: string;
}
