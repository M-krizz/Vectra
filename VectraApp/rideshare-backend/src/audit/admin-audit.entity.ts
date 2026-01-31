import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity({ name: 'admin_audit_logs' })
export class AdminAudit {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { nullable: false })
  targetUser: User;

  @ManyToOne(() => User, { nullable: true })
  performedBy: User | null;

  @Column({ type: 'varchar', length: 64 })
  action: string; // SUSPEND_USER | REINSTATE_USER

  @Column({ type: 'varchar', length: 255, nullable: true })
  reason: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
