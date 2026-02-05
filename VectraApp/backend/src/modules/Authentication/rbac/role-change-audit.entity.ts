import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { UserEntity, UserRole } from '../users/user.entity';

@Entity({ name: 'role_change_audits' })
export class RoleChangeAuditEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column('uuid', { name: 'user_id' })
  userId!: string;

  @Column('uuid', { name: 'changed_by_id' })
  changedById!: string;

  // ===== Role Change =====
  @Column({ type: 'enum', enum: UserRole, name: 'old_role' })
  oldRole!: UserRole;

  @Column({ type: 'enum', enum: UserRole, name: 'new_role' })
  newRole!: UserRole;

  @Column({ type: 'varchar', length: 500, nullable: true })
  reason!: string | null;

  // ===== Timestamps =====
  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt!: Date;

  // ===== Relations =====
  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @ManyToOne(() => UserEntity, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'changed_by_id' })
  changedBy!: UserEntity;
}
