import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn,
} from 'typeorm';
import { UserEntity } from '../../Authentication/users/user.entity';
import { TripEntity } from '../../trips/trip.entity';

export enum PaymentMethod {
    CASH = 'CASH',
    WALLET = 'WALLET',
    UPI = 'UPI',
    CARD = 'CARD',
}

export enum PaymentStatus {
    PENDING = 'PENDING',
    COMPLETED = 'COMPLETED',
    FAILED = 'FAILED',
    REFUNDED = 'REFUNDED',
}

export enum TransactionType {
    TRIP_FARE = 'TRIP_FARE',
    WALLET_TOPUP = 'WALLET_TOPUP',
    REFUND = 'REFUND',
    WITHDRAWAL = 'WITHDRAWAL', // For drivers
}

@Entity('payments')
export class PaymentEntity {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @ManyToOne(() => UserEntity)
    @JoinColumn({ name: 'user_id' })
    user!: UserEntity;

    @Column({ name: 'user_id' })
    userId!: string;

    @ManyToOne(() => TripEntity, { nullable: true })
    @JoinColumn({ name: 'trip_id' })
    trip?: TripEntity;

    @Column({ name: 'trip_id', nullable: true })
    tripId?: string;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    amount!: number;

    @Column({ type: 'varchar', length: 3, default: 'INR' })
    currency!: string;

    @Column({ type: 'enum', enum: PaymentMethod })
    method!: PaymentMethod;

    @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
    status!: PaymentStatus;

    @Column({ type: 'enum', enum: TransactionType })
    transactionType!: TransactionType;

    @Column({ name: 'gateway_transaction_id', nullable: true })
    gatewayTransactionId?: string; // E.g., Razorpay order_id

    @CreateDateColumn({ name: 'created_at' })
    createdAt!: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt!: Date;
}
