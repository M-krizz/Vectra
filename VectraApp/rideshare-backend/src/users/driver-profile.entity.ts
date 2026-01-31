import { Entity, PrimaryGeneratedColumn, Column, OneToOne, JoinColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { User } from './user.entity';

export enum DriverStatus {
  PENDING_VERIFICATION = 'PENDING_VERIFICATION',
  DOCUMENTS_SUBMITTED = 'DOCUMENTS_SUBMITTED',
  UNDER_REVIEW = 'UNDER_REVIEW',
  VERIFIED = 'VERIFIED',
  SUSPENDED = 'SUSPENDED'
}

@Entity({ name: 'driver_profiles' })
export class DriverProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 64, nullable: true })
  licenseNumber: string | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  licenseState: string | null;

  @Column({ type: 'enum', enum: DriverStatus, default: DriverStatus.PENDING_VERIFICATION })
  status: DriverStatus;

  // emergency contact, background-check id, other metadata
  @Column({ type: 'jsonb', default: {} })
  meta: any;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
