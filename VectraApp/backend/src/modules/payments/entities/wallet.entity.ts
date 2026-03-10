import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    OneToOne,
    JoinColumn,
} from 'typeorm';
import { UserEntity } from '../../Authentication/users/user.entity';

@Entity('wallets')
export class WalletEntity {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @OneToOne(() => UserEntity)
    @JoinColumn({ name: 'user_id' })
    user!: UserEntity;

    @Column({ name: 'user_id', unique: true })
    userId!: string;

    @Column({ type: 'decimal', precision: 10, scale: 2, default: 0.0 })
    balance!: number;

    @Column({ type: 'varchar', length: 3, default: 'INR' })
    currency!: string;

    @Column({ name: 'is_active', default: true })
    isActive!: boolean;

    @CreateDateColumn({ name: 'created_at' })
    createdAt!: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt!: Date;
}
