import { Controller, Post, Body, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { DocumentsService } from './documents.service';
import { PresignRequestDto } from './dto/presign-request.dto';

@Controller('documents')
export class DocumentsController {
  constructor(private docsService: DocumentsService) {}

  /**
   * POST /documents/:driverProfileId/presign
   * returns { url, key, expiresIn }
   */
  @Post(':driverProfileId/presign')
  async presign(@Param('driverProfileId') driverProfileId: string, @Body() dto: PresignRequestDto) {
    const presign = await this.docsService.presignUpload(driverProfileId, dto.originalName, dto.mimeType, dto.size);
    return presign;
  }

  /**
   * POST /documents/:driverProfileId/finalize
   * Body: { key, originalName, mimeType, size, docType }
   * Called by mobile after successful upload to S3 to register metadata.
   */
  @Post(':driverProfileId/finalize')
  @HttpCode(HttpStatus.CREATED)
  async finalize(@Param('driverProfileId') driverProfileId: string, @Body() body: any) {
    const doc = await this.docsService.finalizeDocument(driverProfileId, body.key, body.originalName, body.mimeType, body.size, body.docType);
    return { status: 'ok', doc };
  }
}
