import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserEntity } from '../users/user.entity';

@Entity({ name: 'vehicles' })
export class VehicleEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'driver_user_id' })
  driverUserId!: string;

  // ===== Vehicle Info =====
  @Column({ type: 'varchar', length: 50, name: 'vehicle_type' })
  vehicleType!: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  make!: string | null;

  @Column({ type: 'varchar', length: 50, nullable: true })
  model!: string | null;

  @Column({ type: 'int', nullable: true })
  year!: number | null;

  @Column({ type: 'varchar', length: 30, nullable: true })
  color!: string | null;

  @Column({ type: 'varchar', length: 20, unique: true, name: 'plate_number' })
  plateNumber!: string;

  // ===== Capacity =====
  @Column({ type: 'int', name: 'seating_capacity' })
  seatingCapacity!: number;

  // ===== Environmental =====
  @Column({
    type: 'numeric',
    precision: 10,
    scale: 2,
    nullable: true,
    name: 'emission_factor_g_per_km',
  })
  emissionFactorGPerKm!: number | null;

  // ===== Status =====
  @Column({ type: 'boolean', default: true, name: 'is_active' })
  isActive!: boolean;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt!: Date;

  // ===== Relations =====
  @ManyToOne(() => UserEntity, (user) => user.vehicles, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'driver_user_id' })
  driver!: UserEntity;
}
