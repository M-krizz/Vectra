import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn } from 'typeorm';
import { RideRequest } from '../../rides/entities/ride-request.entity';
import { User } from '../../users/user.entity';

@Entity({ name: 'messages' })
export class Message {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => RideRequest)
    @JoinColumn({ name: 'ride_id' })
    ride: RideRequest;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'sender_id' })
    sender: User;

    @Column({ type: 'text' })
    content: string;

    @CreateDateColumn()
    createdAt: Date;
}
