import { IsNumber, IsEnum, Min, IsOptional, IsString } from 'class-validator';
import { PaymentMethod, TransactionType } from '../entities/payment.entity';

export class TopupWalletDto {
    @IsNumber()
    @Min(1)
    amount!: number;
}

export class WithdrawWalletDto {
    @IsNumber()
    @Min(1)
    amount!: number;
}

export class ProcessTripPaymentDto {
    @IsString()
    tripId!: string;

    @IsEnum(PaymentMethod)
    method!: PaymentMethod;

    @IsOptional()
    @IsString()
    gatewayTransactionId?: string;
}

export class CreateRazorpayOrderDto {
    @IsNumber()
    @Min(1)
    amount!: number; // Amount in INR

    @IsEnum(TransactionType)
    transactionType!: TransactionType;

    @IsOptional()
    @IsString()
    tripId?: string;
}

export class VerifyRazorpayPaymentDto {
    @IsString()
    razorpay_order_id!: string;

    @IsString()
    razorpay_payment_id!: string;

    @IsString()
    razorpay_signature!: string;
}
