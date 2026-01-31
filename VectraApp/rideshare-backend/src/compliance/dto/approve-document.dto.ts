import { IsUUID, IsBoolean, IsOptional, IsString } from 'class-validator';

export class ApproveDocumentDto {
  @IsUUID()
  documentId: string;

  @IsBoolean()
  approve: boolean;

  @IsOptional()
  @IsString()
  adminNotes?: string;
}
