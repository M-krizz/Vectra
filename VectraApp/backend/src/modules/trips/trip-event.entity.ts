import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { TripEntity } from './trip.entity';

@Entity({ name: 'trip_events' })
export class TripEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'trip_id' })
  tripId!: string;

  @Column({ type: 'text', name: 'event_type' })
  eventType!: string;

  @Column({ type: 'text', nullable: true, name: 'old_value' })
  oldValue!: string | null;

  @Column({ type: 'text', nullable: true, name: 'new_value' })
  newValue!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  // Relations
  @ManyToOne(() => TripEntity, (trip) => trip.events, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'trip_id' })
  trip!: TripEntity;
}
