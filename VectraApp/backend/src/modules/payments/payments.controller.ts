import { Controller, Get, Post, Body, UseGuards, Req, Query } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { RolesGuard } from '../Authentication/common/roles.guard';
import { UserRole } from '../Authentication/users/user.entity';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';
import {
    TopupWalletDto,
    WithdrawWalletDto,
    ProcessTripPaymentDto,
    CreateRazorpayOrderDto,
    VerifyRazorpayPaymentDto,
} from './dto/payments.dto';
import { TransactionType } from './entities/payment.entity';

@Controller('api/v1/payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
    constructor(private readonly paymentsService: PaymentsService) { }

    /**
     * GET /api/v1/payments/wallet
     * Get current user's wallet
     */
    @Get('wallet')
    async getWallet(@Req() req: AuthenticatedRequest) {
        return this.paymentsService.getOrCreateWallet(req.user.userId);
    }

    /**
     * GET /api/v1/payments/wallet/transactions
     * Get wallet transaction history for the current user
     */
    @Get('wallet/transactions')
    async getWalletTransactions(
        @Req() req: AuthenticatedRequest,
        @Query('page') page?: string,
        @Query('limit') limit?: string,
        @Query('type') type?: TransactionType,
    ) {
        return this.paymentsService.getWalletTransactions(
            req.user.userId,
            Number(page || 1),
            Number(limit || 20),
            type,
        );
    }

    /**
     * POST /api/v1/payments/wallet/topup
     * Top up wallet balance
     */
    @Post('wallet/topup')
    async topupWallet(@Req() req: AuthenticatedRequest, @Body() dto: TopupWalletDto) {
        return this.paymentsService.topupWallet(req.user.userId, dto);
    }

    /**
     * POST /api/v1/payments/wallet/withdraw
     * Withdraw from wallet balance (driver payout request)
     */
    @Post('wallet/withdraw')
    async withdrawWallet(@Req() req: AuthenticatedRequest, @Body() dto: WithdrawWalletDto) {
        return this.paymentsService.withdrawWallet(req.user.userId, dto);
    }

    /**
     * POST /api/v1/payments/trip
     * Process payment for a completed trip (Legacy mock)
     */
    @Post('trip')
    @Roles(UserRole.RIDER)
    @UseGuards(RolesGuard)
    async processTripPayment(@Req() req: AuthenticatedRequest, @Body() dto: ProcessTripPaymentDto) {
        return this.paymentsService.processTripPayment(req.user.userId, dto);
    }

    /**
     * POST /api/v1/payments/order
     * Create a new Razorpay order
     */
    @Post('order')
    async createOrder(@Req() req: AuthenticatedRequest, @Body() dto: CreateRazorpayOrderDto) {
        return this.paymentsService.createRazorpayOrder(req.user.userId, dto);
    }

    /**
     * POST /api/v1/payments/verify
     * Verify a completed Razorpay payment
     */
    @Post('verify')
    async verifyPayment(@Req() req: AuthenticatedRequest, @Body() dto: VerifyRazorpayPaymentDto) {
        return this.paymentsService.verifyRazorpayPayment(req.user.userId, dto);
    }
}
