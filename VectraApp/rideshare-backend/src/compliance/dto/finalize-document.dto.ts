import { IsString, IsUUID, IsInt, IsOptional } from 'class-validator';

export class FinalizeDocumentDto {
  @IsString()
  key: string; // s3 key returned earlier

  @IsString()
  originalName: string;

  @IsString()
  mimeType: string;

  @IsInt()
  size: number;

  @IsString()
  docType: string;

  @IsOptional()
  @IsString()
  expiresAt?: string; // optional ISO date
}
