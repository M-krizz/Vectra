import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { VehicleType } from '../ride_requests/ride-request.enums';

export enum PoolStatus {
  FORMING = 'FORMING',
  ACTIVE = 'ACTIVE', // Trip started
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED', // Failed to find enough riders or timeout
}

@Entity({ name: 'pool_groups' })
export class PoolGroupEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({
    type: 'enum',
    enum: PoolStatus,
    default: PoolStatus.FORMING,
  })
  status!: PoolStatus;

  @Column({
    type: 'enum',
    enum: VehicleType,
    name: 'vehicle_type',
  })
  vehicleType!: VehicleType;

  @Column({ type: 'int', default: 0, name: 'current_riders_count' })
  currentRidersCount!: number;

  @Column({ type: 'int', default: 3, name: 'max_riders' })
  maxRiders!: number;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt!: Date;

  // Relations
  // We can't import RideRequestEntity directly due to circular dependency if not careful,
  // but TypeORM handles lazy/string imports.
  @OneToMany(() => RideRequestEntity, (request) => request.poolGroupId)
  rideRequests!: RideRequestEntity[];
}
