import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn,
} from 'typeorm';
import { UserEntity } from '../Authentication/users/user.entity';

@Entity({ name: 'incentives' })
export class IncentiveEntity {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @Column('uuid', { name: 'driver_user_id' })
    driverUserId!: string;

    @Column({ type: 'varchar', length: 255 })
    title!: string;

    @Column({ type: 'text', default: '' })
    description!: string;

    @Column({ type: 'numeric', precision: 10, scale: 2, name: 'reward_amount' })
    rewardAmount!: number;

    @Column({ type: 'int', default: 0, name: 'current_progress' })
    currentProgress!: number;

    @Column({ type: 'int', name: 'target_progress' })
    targetProgress!: number;

    @Column({ type: 'timestamptz', nullable: true, name: 'expires_at' })
    expiresAt!: Date | null;

    @Column({ type: 'boolean', default: false, name: 'is_completed' })
    isCompleted!: boolean;

    @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
    createdAt!: Date;

    @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
    updatedAt!: Date;

    @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'driver_user_id' })
    driver!: UserEntity;
}
