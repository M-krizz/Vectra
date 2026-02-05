import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserEntity } from '../users/user.entity';

/**
 * Driver verification status
 */
export enum DriverStatus {
  PENDING_VERIFICATION = 'PENDING_VERIFICATION',
  DOCUMENTS_SUBMITTED = 'DOCUMENTS_SUBMITTED',
  UNDER_REVIEW = 'UNDER_REVIEW',
  VERIFIED = 'VERIFIED',
  SUSPENDED = 'SUSPENDED',
}

/**
 * DriverProfile metadata interface
 */
export interface DriverMeta {
  emergencyContact?: {
    name: string;
    phone: string;
    relationship: string;
  };
  backgroundCheckId?: string;
  [key: string]: unknown;
}

@Entity({ name: 'driver_profiles' })
export class DriverProfileEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'user_id' })
  userId!: string;

  // ===== License Info =====
  @Column({
    type: 'varchar',
    length: 64,
    nullable: true,
    name: 'license_number',
  })
  licenseNumber!: string | null;

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    name: 'license_state',
  })
  licenseState!: string | null;

  // ===== Verification Status =====
  @Column({
    type: 'enum',
    enum: DriverStatus,
    default: DriverStatus.PENDING_VERIFICATION,
  })
  status!: DriverStatus;

  // ===== Ratings =====
  @Column({
    type: 'numeric',
    precision: 3,
    scale: 2,
    default: 0,
    name: 'rating_avg',
  })
  ratingAvg!: number;

  @Column({ type: 'int', default: 0, name: 'rating_count' })
  ratingCount!: number;

  @Column({
    type: 'numeric',
    precision: 5,
    scale: 2,
    default: 0,
    name: 'completion_rate',
  })
  completionRate!: number;

  // ===== Online Status =====
  @Column({ type: 'boolean', default: false, name: 'online_status' })
  onlineStatus!: boolean;

  // ===== Metadata =====
  @Column({ type: 'jsonb', default: {} })
  meta!: DriverMeta;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt!: Date;

  // ===== Relations =====
  @OneToOne(() => UserEntity, (user) => user.driverProfile, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;
}
