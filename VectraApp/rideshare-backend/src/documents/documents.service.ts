import { Injectable, BadRequestException } from '@nestjs/common';
import { S3Service } from '../storage/s3.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Document } from '../users/document.entity';
import { DriverProfile } from '../users/driver-profile.entity';

@Injectable()
export class DocumentsService {
  constructor(
    private s3: S3Service,
    @InjectRepository(Document) private docsRepo: Repository<Document>,
    @InjectRepository(DriverProfile) private profilesRepo: Repository<DriverProfile>,
  ) {}

  async presignUpload(driverProfileId: string, originalName: string, mimeType: string, size: number) {
    // validate size & type at server-side too
    const allowedTypes = ['image/jpeg','image/png','application/pdf'];
    if (!allowedTypes.includes(mimeType)) {
      throw new BadRequestException('Unsupported file type');
    }
    if (size > 5 * 1024 * 1024) {
      throw new BadRequestException('File too large (max 5MB)');
    }
    // ensure driver exists
    const profile = await this.profilesRepo.findOne({ where: { id: driverProfileId }});
    if (!profile) throw new BadRequestException('Driver profile not found');

    const presign = await this.s3.getPresignedUploadUrl(originalName, mimeType, driverProfileId);
    return presign;
  }

  async finalizeDocument(driverProfileId: string, s3Key: string, originalName: string, mimeType: string, size: number, docType: string) {
    const profile = await this.profilesRepo.findOne({ where: { id: driverProfileId }});
    if (!profile) throw new BadRequestException('Driver profile not found');

    const doc = this.docsRepo.create({
      driverProfile: profile,
      s3Key,
      originalName,
      mimeType,
      sizeBytes: size,
      docType,
      isApproved: false,
      expiresAt: null,
    });
    return await this.docsRepo.save(doc);
  }
}
