import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Document } from './entities/document.entity';
import { DriverProfile } from '../users/driver-profile.entity';
import { S3Service } from '../storage/s3.service';
import { ComplianceEvent } from './entities/compliance-event.entity';
import { User } from '../users/user.entity';

@Injectable()
export class DocumentsService {
  private logger = new Logger(DocumentsService.name);

  constructor(
    @InjectRepository(Document) private docsRepo: Repository<Document>,
    @InjectRepository(DriverProfile) private profilesRepo: Repository<DriverProfile>,
    @InjectRepository(ComplianceEvent) private eventsRepo: Repository<ComplianceEvent>,
    private s3: S3Service,
  ) {}

  async presignUpload(driverProfileId: string, dto: { originalName: string; mimeType: string; size: number; docType: string; expiresAt?: string; }) {
    // validate profile exists
    const profile = await this.profilesRepo.findOne({ where: { id: driverProfileId }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');

    // basic size/mime checks
    const allowed = ['image/jpeg','image/png','application/pdf'];
    if (!allowed.includes(dto.mimeType)) {
      throw new BadRequestException('Unsupported file type');
    }
    if (dto.size > 10 * 1024 * 1024) throw new BadRequestException('file too large');

    // get presigned url
    return await this.s3.getPresignedUploadUrl(dto.originalName, dto.mimeType, profile.user.id);
  }

  async finalizeDocument(driverProfileId: string, body: { key: string; originalName: string; mimeType: string; size: number; docType: string; expiresAt?: string; }) {
    const profile = await this.profilesRepo.findOne({ where: { id: driverProfileId }, relations: ['user'] });
    if (!profile) throw new NotFoundException('Driver profile not found');

    const doc = this.docsRepo.create({
      driverProfile: profile,
      s3Key: body.key,
      originalName: body.originalName,
      mimeType: body.mimeType,
      sizeBytes: body.size,
      docType: body.docType,
      expiresAt: body.expiresAt ? new Date(body.expiresAt) : null,
      isApproved: false,
      approvedByAdminId: null,
      adminNotes: null,
    });
    const saved = await this.docsRepo.save(doc);

    // record event
    await this.eventsRepo.save({
      driverProfile: profile,
      eventType: 'DOCUMENT_UPLOADED',
      meta: { documentId: saved.id, docType: saved.docType },
    });

    return saved;
  }

  async listDocuments(driverProfileId: string) {
    return await this.docsRepo.find({ where: { driverProfile: { id: driverProfileId } }});
  }

  async getDocument(documentId: string) {
    const d = await this.docsRepo.findOne({ where: { id: documentId }, relations: ['driverProfile']});
    if (!d) throw new NotFoundException('Document not found');
    return d;
  }
  async listPending() {
  return await this.docsRepo.find({ where: { isApproved: false }, relations: ['driverProfile'] });
}

  async adminApprove(documentId: string, admin: User, approve: boolean, notes?: string) {
    const doc = await this.getDocument(documentId);
    doc.isApproved = approve;
    doc.approvedByAdminId = admin.id;
    doc.adminNotes = notes ?? null;
    await this.docsRepo.save(doc);

    await this.eventsRepo.save({
      driverProfile: doc.driverProfile,
      eventType: approve ? 'DOCUMENT_APPROVED' : 'DOCUMENT_REJECTED',
      meta: { documentId: doc.id, adminId: admin.id, notes },
    });

    return doc;
  }
}
