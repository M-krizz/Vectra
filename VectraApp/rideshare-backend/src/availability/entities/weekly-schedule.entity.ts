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
 * WeeklySchedule:
 * - driverProfile: owner
 * - dayOfWeek: 0 (Sunday) .. 6 (Saturday)
 * - startTime / endTime: stored as "HH:MM" 24-hour strings, e.g. "08:30"
 *
 * Mobile UI will send an array of windows for each day.
 */
@Entity({ name: 'weekly_schedules' })
export class WeeklySchedule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => DriverProfile, { onDelete: 'CASCADE' })
  driverProfile: DriverProfile;

  @Column({ type: 'int' })
  dayOfWeek: number; // 0..6

  @Column({ type: 'varchar', length: 5 })
  startTime: string; // "HH:MM"

  @Column({ type: 'varchar', length: 5 })
  endTime: string; // "HH:MM"

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
