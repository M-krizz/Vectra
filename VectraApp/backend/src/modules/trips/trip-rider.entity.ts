import { Entity, Column, ManyToOne, JoinColumn, PrimaryColumn } from 'typeorm';
import { UserEntity } from '../Authentication/users/user.entity';
import { TripEntity } from './trip.entity';
import { GeoPoint } from '../../common/types/geo-point.type';

export enum TripRiderStatus {
  JOINED = 'JOINED',
  CANCELLED = 'CANCELLED',
  NO_SHOW = 'NO_SHOW',
}

@Entity({ name: 'trip_riders' })
export class TripRiderEntity {
  @PrimaryColumn('uuid', { name: 'trip_id' })
  tripId!: string;

  @PrimaryColumn('uuid', { name: 'rider_user_id' })
  riderUserId!: string;

  // PostGIS Geography points
  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    name: 'pickup_point',
  })
  pickupPoint!: GeoPoint;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    name: 'drop_point',
  })
  dropPoint!: GeoPoint;

  @Column({ type: 'int', nullable: true, name: 'pickup_sequence' })
  pickupSequence!: number | null;

  @Column({ type: 'int', nullable: true, name: 'drop_sequence' })
  dropSequence!: number | null;

  @Column({
    type: 'numeric',
    precision: 10,
    scale: 2,
    nullable: true,
    name: 'fare_share',
  })
  fareShare!: number | null;

  @Column({
    type: 'enum',
    enum: TripRiderStatus,
    default: TripRiderStatus.JOINED,
  })
  status!: TripRiderStatus;

  // Relations
  @ManyToOne(() => TripEntity, (trip) => trip.tripRiders, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'trip_id' })
  trip!: TripEntity;

  @ManyToOne(() => UserEntity, (user) => user.tripRiders, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'rider_user_id' })
  rider!: UserEntity;
}
