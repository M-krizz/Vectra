import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  OneToMany,
} from 'typeorm';

/**
 * User roles in the system
 */
export enum UserRole {
  RIDER = 'RIDER',
  DRIVER = 'DRIVER',
  ADMIN = 'ADMIN',
  COMMUNITY_ADMIN = 'COMMUNITY_ADMIN',
}

/**
 * Account status for administrative actions
 */
export enum AccountStatus {
  ACTIVE = 'ACTIVE',
  SUSPENDED = 'SUSPENDED',
  DELETED = 'DELETED',
}

/**
 * Preferred location structure for riders
 */
export interface PreferredLocation {
  name: string;
  lat: number;
  lng: number;
  address?: string;
}

@Entity({ name: 'users' })
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  // ===== Basic Info =====
  @Column({ type: 'varchar', length: 320, unique: true, nullable: true })
  email!: string | null;

  @Column({ type: 'varchar', length: 24, unique: true, nullable: true })
  phone!: string | null;

  @Column({ type: 'varchar', length: 150, nullable: true, name: 'full_name' })
  fullName!: string | null;

  @Column({ type: 'text', nullable: true, name: 'password_hash' })
  passwordHash!: string | null;

  // ===== Role & Status =====
  @Column({ type: 'enum', enum: UserRole, default: UserRole.RIDER })
  role!: UserRole;

  @Column({ type: 'enum', enum: AccountStatus, default: AccountStatus.ACTIVE })
  status!: AccountStatus;

  // ===== Verification =====
  @Column({ type: 'boolean', default: false, name: 'is_verified' })
  isVerified!: boolean;

  // ===== Profile =====
  @Column({
    type: 'varchar',
    length: 255,
    nullable: true,
    name: 'profile_image_key',
  })
  profileImageKey!: string | null;

  @Column({ type: 'jsonb', default: [], name: 'preferred_locations' })
  preferredLocations!: PreferredLocation[];

  // ===== Privacy Settings =====
  @Column({ type: 'boolean', default: true, name: 'share_location' })
  shareLocation!: boolean;

  @Column({ type: 'boolean', default: true, name: 'share_ride_history' })
  shareRideHistory!: boolean;

  // ===== Account State =====
  @Column({ type: 'boolean', default: true, name: 'is_active' })
  isActive!: boolean;

  @Column({ type: 'boolean', default: false, name: 'is_suspended' })
  isSuspended!: boolean;

  @Column({
    type: 'varchar',
    length: 255,
    nullable: true,
    name: 'suspension_reason',
  })
  suspensionReason!: string | null;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt!: Date;

  @Column({ type: 'timestamptz', nullable: true, name: 'last_login_at' })
  lastLoginAt!: Date | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'deleted_at' })
  deletedAt!: Date | null;

  // ===== Relations (using string references to avoid circular deps) =====
  @OneToOne('DriverProfileEntity', 'user')
  driverProfile?: unknown;

  @OneToMany('VehicleEntity', 'driver')
  vehicles?: unknown[];

  @OneToMany('RideRequestEntity', 'rider')
  rideRequests?: unknown[];

  @OneToMany('TripEntity', 'driver')
  driverTrips?: unknown[];

  @OneToMany('TripRiderEntity', 'rider')
  tripRiders?: unknown[];

  @OneToMany('RefreshTokenEntity', 'user')
  refreshTokens?: unknown[];

  @OneToMany('AdminAuditEntity', 'performedBy')
  performedAudits?: unknown[];

  @OneToMany('AdminAuditEntity', 'targetUser')
  targetedAudits?: unknown[];
}
