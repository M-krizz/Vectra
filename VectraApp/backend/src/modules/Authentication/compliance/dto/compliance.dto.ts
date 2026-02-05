import { IsString, IsOptional, IsEnum } from 'class-validator';
import { DocumentType } from '../document.entity';

export class PresignRequestDto {
  @IsEnum(DocumentType)
  docType!: DocumentType;

  @IsString()
  fileName!: string;

  @IsString()
  contentType!: string;
}

export class FinalizeDocumentDto {
  @IsString()
  documentId!: string;
}

export class ApproveDocumentDto {
  @IsString()
  documentId!: string;

  @IsOptional()
  @IsString()
  expiresAt?: string; // ISO date string
}

export class RejectDocumentDto {
  @IsString()
  documentId!: string;

  @IsString()
  reason!: string;
}
