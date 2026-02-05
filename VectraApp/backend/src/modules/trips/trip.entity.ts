import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { UserEntity } from '../Authentication/users/user.entity';
import { TripRiderEntity } from './trip-rider.entity';
import { TripEventEntity } from './trip-event.entity';

export enum TripStatus {
  REQUESTED = 'REQUESTED',
  ASSIGNED = 'ASSIGNED',
  ARRIVING = 'ARRIVING',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

@Entity({ name: 'trips' })
export class TripEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { nullable: true, name: 'driver_user_id' })
  driverUserId!: string | null;

  @Column({
    type: 'enum',
    enum: TripStatus,
    default: TripStatus.REQUESTED,
  })
  status!: TripStatus;

  @Column({ type: 'timestamptz', nullable: true, name: 'assigned_at' })
  assignedAt!: Date | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'start_at' })
  startAt!: Date | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'end_at' })
  endAt!: Date | null;

  @Column({ type: 'text', nullable: true, name: 'current_route_polyline' })
  currentRoutePolyline!: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt!: Date;

  // Relations
  @ManyToOne(() => UserEntity, (user) => user.driverTrips, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'driver_user_id' })
  driver!: UserEntity | null;

  @OneToMany(() => TripRiderEntity, (tripRider) => tripRider.trip)
  tripRiders!: TripRiderEntity[];

  @OneToMany(() => TripEventEntity, (event) => event.trip)
  events!: TripEventEntity[];
}
