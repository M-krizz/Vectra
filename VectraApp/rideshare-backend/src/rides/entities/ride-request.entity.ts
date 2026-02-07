import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { User } from '../../users/user.entity';

export enum RideStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  EN_ROUTE = 'EN_ROUTE',
  ARRIVED = 'ARRIVED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED'
}

@Entity({ name: 'ride_requests' })
export class RideRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'rider_id' })
  rider: User;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'driver_id' })
  driver: User | null;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true
  })
  @Index({ spatial: true })
  pickupLocation: string; // WKT format: POINT(lng lat)

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true
  })
  @Index({ spatial: true })
  dropoffLocation: string;

  @Column({ type: 'varchar', nullable: true })
  pickupAddress: string | null;

  @Column({ type: 'varchar', nullable: true })
  dropoffAddress: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  fare: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  distance: number; // in km

  @Column({ type: 'enum', enum: RideStatus, default: RideStatus.PENDING })
  status: RideStatus;

  @Column({ type: 'timestamp', nullable: true })
  assignedAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
