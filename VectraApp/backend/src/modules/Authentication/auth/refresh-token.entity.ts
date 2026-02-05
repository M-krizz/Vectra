import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';
import { UserEntity } from '../users/user.entity';

@Entity({ name: 'refresh_tokens' })
export class RefreshTokenEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Index()
  @Column({ type: 'uuid', name: 'user_id' })
  userId!: string;

  // ===== Token Hash =====
  @Column({ type: 'text', name: 'token_hash' })
  tokenHash!: string;

  // ===== Device Info (from teammate) =====
  @Column({ type: 'varchar', length: 255, nullable: true, name: 'device_info' })
  deviceInfo!: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  ip!: string | null;

  // ===== Expiry & Revocation =====
  @Column({ type: 'timestamptz', name: 'expires_at' })
  expiresAt!: Date;

  @Column({ type: 'timestamptz', nullable: true, name: 'revoked_at' })
  revokedAt!: Date | null;

  @Column({ type: 'timestamptz', nullable: true, name: 'last_used_at' })
  lastUsedAt!: Date | null;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  // ===== Relations =====
  @ManyToOne(() => UserEntity, (user) => user.refreshTokens, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;
}
