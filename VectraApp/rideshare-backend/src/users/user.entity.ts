import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  BeforeInsert,
} from 'typeorm';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Either email or phone (or both)
  @Column({ type: 'varchar', length: 320, unique: true, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 24, unique: true, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 150 })
  fullName: string;

  // hashed password if user supplies one during registration
  @Column({ type: 'varchar', nullable: true })
  passwordHash: string | null;

  // Role: RIDER, DRIVER, ADMIN
  @Column({ type: 'varchar', length: 20, default: 'RIDER' })
  role: string;

  // store location preferences as JSON, e.g., [{ "name":"Home", "lat":12.9, "lng":77.5 }]
  @Column({ type: 'jsonb', default: [] })
  preferredLocations: any[];

  @Column({ type: 'boolean', default: false })
  isVerified: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // add these columns to existing User entity

@Column({ type: 'varchar', nullable: true })
profileImageKey: string | null;

@Column({ type: 'boolean', default: true })
shareLocation: boolean;

@Column({ type: 'boolean', default: true })
shareRideHistory: boolean;

@Column({ type: 'boolean', default: true })
isActive: boolean; // for deactivation

@Column({ type: 'timestamp', nullable: true })
deletedAt: Date | null;

@Column({ type: 'boolean', default: false })
isSuspended: boolean;

@Column({ type: 'varchar', length: 255, nullable: true })
suspensionReason: string | null;


}
