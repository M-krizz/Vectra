import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { DriverProfile } from '../../users/driver-profile.entity';

@Entity({ name: 'compliance_events' })
export class ComplianceEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => DriverProfile, { onDelete: 'CASCADE' })
  driverProfile: DriverProfile;

  @Column({ type: 'varchar', length: 64 })
  eventType: string; // e.g., 'DOCUMENT_UPLOADED', 'DOCUMENT_APPROVED', 'DOCUMENT_REJECTED', 'EXPIRED', 'SUSPENDED', 'RENEWAL_REQUESTED'

  @Column({ type: 'jsonb', nullable: true })
  meta: any;

  @CreateDateColumn()
  createdAt: Date;
}
