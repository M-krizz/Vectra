import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { DriverProfile } from './driver-profile.entity';

export type VehicleType = 'SEDAN'|'SUV'|'EV'|'BIKE';

@Entity({ name: 'vehicles' })
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => DriverProfile)
  driverProfile: DriverProfile;

  @Column({ type: 'varchar', length: 100 })
  model: string;

  @Column({ type: 'varchar', length: 20 })
  plateNumber: string;

  @Column({ type: 'int' })
  seatingCapacity: number;

  @Column({ type: 'varchar', length: 20 })
  vehicleType: VehicleType;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
