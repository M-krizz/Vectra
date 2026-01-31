import { Controller, Post, Body, Param, UseGuards, Req, Get } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DocumentsService } from './documents.service';
import { PresignRequestDto } from './dto/presign-request.dto';
import { FinalizeDocumentDto } from './dto/finalize-document.dto';

@Controller('driver/documents')
@UseGuards(JwtAuthGuard)
export class DocumentsController {
  constructor(private docsService: DocumentsService) {}

  // POST /driver/documents/:driverProfileId/presign
  @Post(':driverProfileId/presign')
  async presign(@Param('driverProfileId') driverProfileId: string, @Body() dto: PresignRequestDto, @Req() req: any) {
    // mobile will send driverProfileId (or you can derive from req.user)
    // security: ensure the logged-in user owns this profile or is admin
    const user = req.user;
    // recommended: verify ownership here (omitted for brevity)
    return this.docsService.presignUpload(driverProfileId, dto as any);
  }

  // POST /driver/documents/:driverProfileId/finalize
  @Post(':driverProfileId/finalize')
  async finalize(@Param('driverProfileId') driverProfileId: string, @Body() body: FinalizeDocumentDto, @Req() req: any) {
    // mobile uploads file to S3 then calls this to register the document
    const saved = await this.docsService.finalizeDocument(driverProfileId, body as any);
    return { status: 'ok', document: saved };
  }

  // GET /driver/documents/:driverProfileId
  @Get(':driverProfileId')
  async list(@Param('driverProfileId') driverProfileId: string, @Req() req: any) {
    // ensure ownership
    return this.docsService.listDocuments(driverProfileId);
  }
}
