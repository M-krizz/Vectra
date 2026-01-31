import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DriverProfile } from '../../users/driver-profile.entity';

/**
 * TimeOff:
 * - driverProfile
 * - startAt / endAt: ISO timestamps
 * - status: PENDING / APPROVED / REJECTED (admin can approve; for simplicity drivers can create auto-approved)
 */
@Entity({ name: 'timeoffs' })
export class TimeOff {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => DriverProfile, { onDelete: 'CASCADE' })
  driverProfile: DriverProfile;

  @Column({ type: 'timestamp' })
  startAt: Date;

  @Column({ type: 'timestamp' })
  endAt: Date;

  @Column({ type: 'varchar', length: 20, default: 'APPROVED' })
  status: 'PENDING' | 'APPROVED' | 'REJECTED';

  @Column({ type: 'varchar', length: 255, nullable: true })
  reason: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
