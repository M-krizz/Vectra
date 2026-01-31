import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from 'typeorm';
import { User } from '../users/user.entity';

/**
 * Track role changes for audit (FR1.3.8)
 */
@Entity({ name: 'role_change_audit' })
export class RoleChangeAudit {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { nullable: false })
  targetUser: User;

  @ManyToOne(() => User, { nullable: true })
  performedBy: User | null; // admin who performed the change (null if system)

  @Column({ type: 'varchar', length: 64 })
  oldRole: string;

  @Column({ type: 'varchar', length: 64 })
  newRole: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  reason: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
