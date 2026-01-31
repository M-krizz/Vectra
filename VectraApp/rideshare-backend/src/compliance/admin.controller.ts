import { Controller, Post, Body, UseGuards, Req, Get, Param } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DocumentsService } from './documents.service';
import { ApproveDocumentDto } from './dto/approve-document.dto';
import { PermissionsGuard } from '../rbac/permissions.guard';
import { Permissions } from '../rbac/permissions.decorator';

@Controller('admin/compliance')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class AdminComplianceController {
  constructor(private docsService: DocumentsService) {}

  // List pending docs (simple helper)
  @Permissions('user:manage')
  @Get('pending')
  async pending() {
    // This should return documents needing review (isApproved == false)
    return this.docsService.listPending();
  }

  // Approve / Reject
  @Permissions('user:manage')
  @Post('document/approve')
  async approve(@Body() body: ApproveDocumentDto, @Req() req: any) {
    const admin = req.user;
    const doc = await this.docsService.adminApprove(body.documentId, admin as any, body.approve, body.adminNotes);
    return { status: 'ok', document: doc };
  }
}
