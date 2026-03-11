import * as crypto from 'crypto';
import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaymentEntity, PaymentStatus, TransactionType, PaymentMethod } from './entities/payment.entity';
import { WalletEntity } from './entities/wallet.entity';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripRiderEntity } from '../trips/trip-rider.entity';
import {
    TopupWalletDto,
    WithdrawWalletDto,
    ProcessTripPaymentDto,
    CreateRazorpayOrderDto,
    VerifyRazorpayPaymentDto,
} from './dto/payments.dto';

const Razorpay = require('razorpay');

@Injectable()
export class PaymentsService {
    private readonly logger = new Logger(PaymentsService.name);
    private razorpay: any;

    constructor(
        @InjectRepository(PaymentEntity)
        private readonly paymentRepo: Repository<PaymentEntity>,
        @InjectRepository(WalletEntity)
        private readonly walletRepo: Repository<WalletEntity>,
        @InjectRepository(TripEntity)
        private readonly tripRepo: Repository<TripEntity>,
        @InjectRepository(TripRiderEntity)
        private readonly tripRiderRepo: Repository<TripRiderEntity>,
    ) {
        this.razorpay = new (Razorpay as any)({
            key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
            key_secret: process.env.RAZORPAY_KEY_SECRET || 'rzp_secret_placeholder',
        });
    }

    /**
     * Ensure user has a wallet
     */
    async getOrCreateWallet(userId: string): Promise<WalletEntity> {
        let wallet = await this.walletRepo.findOne({ where: { userId } });
        if (!wallet) {
            wallet = this.walletRepo.create({ userId, balance: 0.0 });
            await this.walletRepo.save(wallet);
            this.logger.log(`Created wallet for user ${userId}`);
        }
        return wallet;
    }

    /**
     * Top up wallet (Mock implementation for now)
     */
    async topupWallet(userId: string, dto: TopupWalletDto): Promise<WalletEntity> {
        const minTopup = Number(process.env.WALLET_MIN_TOPUP || 10);
        const maxTopup = Number(process.env.WALLET_MAX_TOPUP || 10000);

        if (dto.amount < minTopup || dto.amount > maxTopup) {
            throw new BadRequestException(`Amount must be between ${minTopup} and ${maxTopup}`);
        }

        const wallet = await this.getOrCreateWallet(userId);

        // Create payment record
        const payment = this.paymentRepo.create({
            userId,
            amount: dto.amount,
            method: PaymentMethod.UPI, // Defaulting to UPI for mock
            status: PaymentStatus.COMPLETED, // Auto-completing for mock
            transactionType: TransactionType.WALLET_TOPUP,
            gatewayTransactionId: `mock_topup_${Date.now()}`,
        });
        await this.paymentRepo.save(payment);

        // Update balance
        wallet.balance = Number(wallet.balance) + Number(dto.amount);
        return this.walletRepo.save(wallet);
    }

    /**
     * Withdraw from wallet balance.
     * This records a WITHDRAWAL transaction and deducts from wallet.
     */
    async withdrawWallet(userId: string, dto: WithdrawWalletDto): Promise<WalletEntity> {
        const minWithdraw = Number(process.env.WALLET_MIN_WITHDRAW || 100);
        const maxWithdraw = Number(process.env.WALLET_MAX_WITHDRAW || 50000);

        if (dto.amount < minWithdraw || dto.amount > maxWithdraw) {
            throw new BadRequestException(`Amount must be between ${minWithdraw} and ${maxWithdraw}`);
        }

        const wallet = await this.getOrCreateWallet(userId);
        const currentBalance = Number(wallet.balance);

        if (currentBalance < Number(dto.amount)) {
            throw new BadRequestException('Insufficient wallet balance');
        }

        const payment = this.paymentRepo.create({
            userId,
            amount: dto.amount,
            method: PaymentMethod.WALLET,
            status: PaymentStatus.COMPLETED,
            transactionType: TransactionType.WITHDRAWAL,
            gatewayTransactionId: `withdraw_${Date.now()}`,
        });
        await this.paymentRepo.save(payment);

        wallet.balance = currentBalance - Number(dto.amount);
        return this.walletRepo.save(wallet);
    }

    /**
     * Get wallet transaction history for current user.
     */
    async getWalletTransactions(
        userId: string,
        page = 1,
        limit = 20,
        type?: TransactionType,
    ) {
        const safePage = Number.isFinite(page) && page > 0 ? page : 1;
        const safeLimit = Number.isFinite(limit) && limit > 0 ? Math.min(limit, 100) : 20;

        const qb = this.paymentRepo
            .createQueryBuilder('payment')
            .where('payment.userId = :userId', { userId });

        if (type) {
            qb.andWhere('payment.transactionType = :type', { type });
        }

        qb.orderBy('payment.createdAt', 'DESC')
            .skip((safePage - 1) * safeLimit)
            .take(safeLimit);

        const [items, total] = await qb.getManyAndCount();

        return {
            items: items.map((payment) => ({
                id: payment.id,
                type: this.mapPaymentTypeForClient(payment.transactionType),
                amount: Number(payment.amount),
                description: this.buildDescription(payment),
                timestamp: payment.createdAt.toISOString(),
                tripId: payment.tripId,
                referenceId: payment.gatewayTransactionId,
            })),
            total,
            page: safePage,
            limit: safeLimit,
        };
    }

    private mapPaymentTypeForClient(type: TransactionType): string {
        switch (type) {
            case TransactionType.TRIP_FARE:
                return 'earning';
            case TransactionType.WALLET_TOPUP:
                return 'bonus';
            case TransactionType.REFUND:
                return 'refund';
            case TransactionType.WITHDRAWAL:
                return 'withdrawal';
            default:
                return 'earning';
        }
    }

    private buildDescription(payment: PaymentEntity): string {
        switch (payment.transactionType) {
            case TransactionType.TRIP_FARE:
                return payment.tripId
                    ? `Trip earning (${payment.tripId.slice(0, 8)})`
                    : 'Trip earning';
            case TransactionType.WALLET_TOPUP:
                return 'Wallet top-up';
            case TransactionType.REFUND:
                return 'Refund';
            case TransactionType.WITHDRAWAL:
                return 'Wallet withdrawal';
            default:
                return 'Wallet transaction';
        }
    }

    /**
     * Process payment for a completed trip (Rider side)
     */
    async processTripPayment(userId: string, dto: ProcessTripPaymentDto): Promise<PaymentEntity> {
        const trip = await this.tripRepo.findOne({ where: { id: dto.tripId } });
        if (!trip) throw new NotFoundException('Trip not found');

        if (trip.status !== TripStatus.COMPLETED) {
            throw new BadRequestException('Can only pay for completed trips');
        }

        const tripRider = await this.tripRiderRepo.findOne({
            where: { tripId: dto.tripId, riderUserId: userId }
        });

        if (!tripRider) throw new NotFoundException('User is not a rider on this trip');
        if (tripRider.paymentStatus === PaymentStatus.COMPLETED) {
            throw new BadRequestException('Trip fare already paid');
        }

        const amount = Number(tripRider.fareShare);

        // If paying by wallet, check balance and deduct
        if (dto.method === PaymentMethod.WALLET) {
            const wallet = await this.getOrCreateWallet(userId);
            if (Number(wallet.balance) < amount) {
                throw new BadRequestException('Insufficient wallet balance');
            }
            wallet.balance = Number(wallet.balance) - amount;
            await this.walletRepo.save(wallet);
        }

        // Create Payment Record
        const payment = this.paymentRepo.create({
            userId,
            tripId: trip.id,
            amount,
            method: dto.method,
            status: PaymentStatus.COMPLETED, // Assuming success for mock/cash
            transactionType: TransactionType.TRIP_FARE,
            gatewayTransactionId: dto.gatewayTransactionId || `mock_fare_${Date.now()}`,
        });

        const savedPayment = await this.paymentRepo.save(payment);

        // Mark tripRider as paid
        tripRider.paymentStatus = PaymentStatus.COMPLETED;
        await this.tripRiderRepo.save(tripRider);

        return savedPayment;
    }

    /**
     * Create a new Razorpay order
     */
    async createRazorpayOrder(userId: string, dto: CreateRazorpayOrderDto) {
        const amountInPaise = Math.round(dto.amount * 100);

        const options = {
            amount: amountInPaise,
            currency: 'INR',
            receipt: `rcptid_${userId.slice(0, 5)}_${Date.now()}`,
        };

        const order = await this.razorpay.orders.create(options);

        // Create a pending payment record
        const payment = this.paymentRepo.create({
            userId,
            amount: dto.amount,
            method: PaymentMethod.CARD, // Standardizing to CARD for generic online pay
            status: PaymentStatus.PENDING,
            transactionType: dto.transactionType,
            gatewayTransactionId: order.id,
            tripId: dto.tripId,
        });

        await this.paymentRepo.save(payment);

        return {
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
        };
    }

    /**
     * Verify Razorpay payment signature
     */
    async verifyRazorpayPayment(userId: string, dto: VerifyRazorpayPaymentDto) {
        // Verify signature
        const secret = process.env.RAZORPAY_KEY_SECRET || 'rzp_secret_placeholder';
        const body = dto.razorpay_order_id + '|' + dto.razorpay_payment_id;

        const expectedSignature = crypto
            .createHmac('sha256', secret)
            .update(body.toString())
            .digest('hex');

        if (expectedSignature !== dto.razorpay_signature) {
            throw new BadRequestException('Invalid signature');
        }

        // Find payment
        const payment = await this.paymentRepo.findOne({
            where: { gatewayTransactionId: dto.razorpay_order_id }
        });

        if (!payment) {
            throw new NotFoundException('Payment record not found for this order');
        }

        if (payment.status === PaymentStatus.COMPLETED) {
            return { success: true, message: 'Payment already verified' };
        }

        payment.status = PaymentStatus.COMPLETED;
        payment.updatedAt = new Date();
        await this.paymentRepo.save(payment);

        // Fulfill business logic based on transaction type
        if (payment.transactionType === TransactionType.WALLET_TOPUP) {
            const wallet = await this.getOrCreateWallet(payment.userId);
            wallet.balance = Number(wallet.balance) + Number(payment.amount);
            await this.walletRepo.save(wallet);
            this.logger.log(`Wallet topped up for user ${payment.userId} by ${payment.amount}`);
        } else if (payment.transactionType === TransactionType.TRIP_FARE && payment.tripId) {
            const tripRider = await this.tripRiderRepo.findOne({
                where: { tripId: payment.tripId, riderUserId: payment.userId }
            });
            if (tripRider) {
                tripRider.paymentStatus = PaymentStatus.COMPLETED;
                await this.tripRiderRepo.save(tripRider);
                this.logger.log(`Trip ${payment.tripId} paid by rider ${payment.userId}`);
            }
        }

        return { success: true, paymentId: payment.id };
    }
}
