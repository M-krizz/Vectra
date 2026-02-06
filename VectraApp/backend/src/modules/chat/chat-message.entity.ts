import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    ManyToOne,
    JoinColumn,
    Index,
} from 'typeorm';
import { UserEntity } from '../users/user.entity';
import { TripEntity } from '../trips/trip.entity';

@Entity({ name: 'chat_messages' })
export class ChatMessageEntity {
    @PrimaryGeneratedColumn('uuid')
    id!: string;

    @Index()
    @Column('uuid', { name: 'trip_id' })
    tripId!: string;

    @Column('uuid', { name: 'sender_id' })
    senderId!: string;

    @Column({ type: 'text' })
    message!: string;

    @CreateDateColumn({ type: 'timestamptz', name: 'sent_at' })
    sentAt!: Date;

    @Column({ type: 'boolean', default: false, name: 'is_read' })
    isRead!: boolean;

    // Relations
    @ManyToOne(() => TripEntity, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'trip_id' })
    trip!: TripEntity;

    @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'sender_id' })
    sender!: UserEntity;
}
