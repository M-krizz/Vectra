import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { UserEntity } from '../Authentication/users/user.entity';
import { PoolGroupEntity } from '../pooling/pool-group.entity';
import { GeoPoint } from '../../common/types/geo-point.type';
import { RideRequestStatus, RideType, VehicleType } from './ride-request.enums';

@Entity({ name: 'ride_requests' })
export class RideRequestEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'rider_user_id' })
  riderUserId!: string;

  // PostGIS Geography points stored as GeoJSON
  @Index('idx_ride_requests_pickup_gist', { spatial: true })
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    name: 'pickup_point',
  })
  pickupPoint!: GeoPoint;

  @Index('idx_ride_requests_drop_gist', { spatial: true })
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    name: 'drop_point',
  })
  dropPoint!: GeoPoint;

  @Column({ type: 'text', nullable: true, name: 'pickup_address' })
  pickupAddress!: string | null;

  @Column({ type: 'text', nullable: true, name: 'drop_address' })
  dropAddress!: string | null;

  @Column({ type: 'enum', enum: RideType, name: 'ride_type' })
  rideType!: RideType;

  @Column({
    type: 'enum',
    enum: VehicleType,
    name: 'vehicle_type',
    default: VehicleType.AUTO,
  })
  vehicleType!: VehicleType;

  @Column({
    type: 'enum',
    enum: RideRequestStatus,
    default: RideRequestStatus.REQUESTED,
  })
  status!: RideRequestStatus;

  @Column('uuid', { nullable: true, name: 'pool_group_id' })
  poolGroupId!: string | null;

  @CreateDateColumn({ type: 'timestamptz', name: 'requested_at' })
  requestedAt!: Date;

  @Column({ type: 'timestamptz', nullable: true, name: 'expires_at' })
  expiresAt!: Date | null;

  // Relations
  @ManyToOne(() => UserEntity, (user) => user.rideRequests, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'rider_user_id' })
  rider!: UserEntity;

  @ManyToOne(() => PoolGroupEntity, (pool) => pool.rideRequests, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'pool_group_id' })
  poolGroup!: PoolGroupEntity | null;
}
