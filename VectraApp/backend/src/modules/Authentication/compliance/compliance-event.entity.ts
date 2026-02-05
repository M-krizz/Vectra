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
 * Compliance event types
 */
export enum ComplianceEventType {
  DOCUMENT_SUBMITTED = 'DOCUMENT_SUBMITTED',
  DOCUMENT_APPROVED = 'DOCUMENT_APPROVED',
  DOCUMENT_REJECTED = 'DOCUMENT_REJECTED',
  DOCUMENT_EXPIRED = 'DOCUMENT_EXPIRED',
  EXPIRY_NOTICE = 'EXPIRY_NOTICE',
  DRIVER_VERIFIED = 'DRIVER_VERIFIED',
  DRIVER_SUSPENDED = 'DRIVER_SUSPENDED',
}

@Entity({ name: 'compliance_events' })
export class ComplianceEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'driver_profile_id' })
  driverProfileId!: string;

  // ===== Event Info =====
  @Column({ type: 'enum', enum: ComplianceEventType, name: 'event_type' })
  eventType!: ComplianceEventType;

  @Column({ type: 'jsonb', default: {} })
  meta!: Record<string, unknown>;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  // ===== Relations =====
  @ManyToOne(() => DriverProfileEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'driver_profile_id' })
  driverProfile!: DriverProfileEntity;
}
