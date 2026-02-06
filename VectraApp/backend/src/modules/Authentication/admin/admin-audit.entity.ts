import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { UserEntity } from '../users/user.entity';

/**
 * Admin action types
 */
export enum AdminAction {
  SUSPEND_USER = 'SUSPEND_USER',
  REINSTATE_USER = 'REINSTATE_USER',
  CHANGE_ROLE = 'CHANGE_ROLE',
  APPROVE_DRIVER = 'APPROVE_DRIVER',
  REJECT_DRIVER = 'REJECT_DRIVER',
  DELETE_USER = 'DELETE_USER',
  BAN_USER = 'BAN_USER',
}

@Entity({ name: 'admin_audits' })
export class AdminAuditEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'performed_by_id' })
  performedById!: string;

  @Column('uuid', { name: 'target_user_id' })
  targetUserId!: string;

  // ===== Action Info =====
  @Column({ type: 'enum', enum: AdminAction })
  action!: AdminAction;

  @Column({ type: 'varchar', length: 500, nullable: true })
  reason!: string | null;

  @Column({ type: 'jsonb', default: {} })
  meta!: Record<string, unknown>;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  // ===== Relations =====
  @ManyToOne(() => UserEntity, (user) => user.performedAudits, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'performed_by_id' })
  performedBy!: UserEntity;

  @ManyToOne(() => UserEntity, (user) => user.targetedAudits, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'target_user_id' })
  targetUser!: UserEntity;
}
