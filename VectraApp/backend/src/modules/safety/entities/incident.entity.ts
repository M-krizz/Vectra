import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserEntity } from '../../Authentication/users/user.entity';
import { RideRequestEntity } from '../../ride_requests/ride-request.entity';
import { IncidentStatus, IncidentSeverity } from '../types/incident.types';

@Entity({ name: 'safety_incidents' })
export class IncidentEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => RideRequestEntity, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'ride_id' })
  ride!: RideRequestEntity | null;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'reported_by_id' })
  reportedBy!: UserEntity;

  @Column({ type: 'text' })
  description!: string;

  @Column({
    type: 'enum',
    enum: IncidentStatus,
    default: IncidentStatus.OPEN,
  })
  status!: IncidentStatus;

  @Column({
    type: 'enum',
    enum: IncidentSeverity,
    default: IncidentSeverity.MEDIUM,
  })
  severity!: IncidentSeverity;

  @Column({ type: 'text', nullable: true })
  resolution!: string | null;

  @Column({ type: 'uuid', nullable: true, name: 'resolved_by_id' })
  resolvedById!: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt!: Date;

  @Column({ type: 'timestamptz', nullable: true, name: 'resolved_at' })
  resolvedAt!: Date | null;
}