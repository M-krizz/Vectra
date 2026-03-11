import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    CreateDateColumn,
    JoinColumn,
} from 'typeorm';
import { UserEntity } from '../../Authentication/users/user.entity';

@Entity('emergency_contacts')
export class EmergencyContactEntity {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @Column()
    name!: string;

    @Column({ name: 'phone_number' })
    phoneNumber!: string;

    @Column({ nullable: true })
    relationship?: string;

    @Column({ name: 'user_id' })
    userId!: string;

    @ManyToOne(() => UserEntity)
    @JoinColumn({ name: 'user_id' })
    user!: UserEntity;

    @CreateDateColumn({ name: 'created_at' })
    createdAt!: Date;
}
