import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from 'typeorm';
import { DriverProfile } from './driver-profile.entity';

export type DocumentType = 'DRIVER_LICENSE'|'VEHICLE_REG'|'PROFILE_PHOTO';

@Entity({ name: 'documents' })
export class Document {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => DriverProfile)
  driverProfile: DriverProfile;

  @Column({ type: 'varchar' })
  s3Key: string;

  @Column({ type: 'varchar' })
  mimeType: string;

  @Column({ type: 'varchar' })
  originalName: string;

  @Column({ type: 'varchar' })
  docType: DocumentType;

  @Column({ type: 'int', nullable: true })
  sizeBytes: number;

  @Column({ type: 'timestamp', nullable: true })
  expiresAt: Date; // if we want to set expiry for temporary access or track doc validity

  @Column({ type: 'boolean', default: false })
  isApproved: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
