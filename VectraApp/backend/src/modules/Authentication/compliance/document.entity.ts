import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { DriverProfileEntity } from '../drivers/driver-profile.entity';

/**
 * Document types for driver verification
 */
export enum DocumentType {
  DRIVERS_LICENSE = 'DRIVERS_LICENSE',
  VEHICLE_REGISTRATION = 'VEHICLE_REGISTRATION',
  INSURANCE = 'INSURANCE',
  BACKGROUND_CHECK = 'BACKGROUND_CHECK',
  PROFILE_PHOTO = 'PROFILE_PHOTO',
}

@Entity({ name: 'documents' })
export class DocumentEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'driver_profile_id' })
  driverProfileId!: string;

  // ===== Document Info =====
  @Column({ type: 'enum', enum: DocumentType, name: 'doc_type' })
  docType!: DocumentType;

  @Column({ type: 'varchar', length: 512, name: 's3_key' })
  s3Key!: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'file_name' })
  fileName!: string | null;

  // ===== Verification =====
  @Column({ type: 'boolean', default: false, name: 'is_approved' })
  isApproved!: boolean;

  @Column({
    type: 'varchar',
    length: 255,
    nullable: true,
    name: 'rejection_reason',
  })
  rejectionReason!: string | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'expires_at' })
  expiresAt!: Date | null;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  // ===== Relations =====
  @ManyToOne(() => DriverProfileEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'driver_profile_id' })
  driverProfile!: DriverProfileEntity;
}
