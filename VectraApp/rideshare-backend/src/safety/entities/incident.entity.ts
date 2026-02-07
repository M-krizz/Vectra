import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../../users/user.entity';
import { RideRequest } from '../../rides/entities/ride-request.entity';

export enum IncidentStatus {
    OPEN = 'OPEN',
    INVESTIGATING = 'INVESTIGATING',
    RESOLVED = 'RESOLVED',
    DISMISSED = 'DISMISSED'
}

@Entity({ name: 'incidents' })
export class Incident {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => RideRequest, { nullable: true })
    @JoinColumn({ name: 'ride_id' })
    ride: RideRequest | null;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'reported_by_id' })
    reportedBy: User;

    @Column({ type: 'text' })
    description: string;

    @Column({ type: 'enum', enum: IncidentStatus, default: IncidentStatus.OPEN })
    status: IncidentStatus;

    @Column({ type: 'text', nullable: true })
    resolution: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
