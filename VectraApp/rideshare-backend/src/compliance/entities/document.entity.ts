import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { DriverProfile } from '../../users/driver-profile.entity';

export type DocumentType = 'DRIVER_LICENSE' | 'VEHICLE_REG' | 'INSURANCE' | 'PROFILE_PHOTO';

@Entity({ name: 'driver_documents' })
export class Document {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => DriverProfile, { onDelete: 'CASCADE' })
  @Index()
  driverProfile: DriverProfile;

  @Column({ type: 'varchar' })
  s3Key: string;

  @Column({ type: 'varchar', length: 200 })
  originalName: string;

  @Column({ type: 'varchar', length: 100 })
  mimeType: string;

  @Column({ type: 'int' })
  sizeBytes: number;

  @Column({ type: 'varchar', length: 32 })
  docType: DocumentType;

  // optional: expiration date encoded in the doc (from driver or from OCR)
  @Column({ type: 'timestamp', nullable: true })
  expiresAt: Date | null;

  @Column({ type: 'boolean', default: false })
  isApproved: boolean;

  @Column({ type: 'varchar', length: 64, nullable: true })
  approvedByAdminId: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  adminNotes: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
