import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  UseGuards,
  Req,
  Patch,
  Delete,
} from '@nestjs/common';
import { SafetyService } from './safety.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { RequirePermissions } from '../Authentication/common/permissions.decorator';
import { PermissionsGuard } from '../Authentication/common/permissions.guard';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';

interface ReportIncidentDto {
  description: string;
  rideId?: string;
}

interface ResolveIncidentDto {
  resolution: string;
}

interface EscalateIncidentDto {
  note?: string;
}

@Controller('api/v1/safety')
@UseGuards(JwtAuthGuard)
export class SafetyController {
  constructor(private readonly safetyService: SafetyService) { }

  @Post('incidents')
  async reportIncident(
    @Req() req: AuthenticatedRequest,
    @Body() body: ReportIncidentDto,
  ) {
    return this.safetyService.reportIncident(
      req.user.userId,
      body.description,
      body.rideId,
    );
  }

  @Get('incidents')
  @RequirePermissions('incident:resolve')
  @UseGuards(PermissionsGuard)
  async listIncidents() {
    return this.safetyService.listIncidents();
  }

  @Patch('incidents/:id/resolve')
  @RequirePermissions('incident:resolve')
  @UseGuards(PermissionsGuard)
  async resolveIncident(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() body: ResolveIncidentDto,
  ) {
    return this.safetyService.resolveIncident(
      id,
      body.resolution,
      req.user.userId,
    );
  }

  @Patch('incidents/:id/escalate')
  @RequirePermissions('incident:resolve')
  @UseGuards(PermissionsGuard)
  async escalateIncident(
    @Param('id') id: string,
    @Body() _body: EscalateIncidentDto,
  ) {
    return this.safetyService.escalateIncident(id);
  }

  @Get('incidents/:id')
  @RequirePermissions('incident:view')
  @UseGuards(PermissionsGuard)
  async getIncident(@Param('id') id: string) {
    return this.safetyService.getIncident(id);
  }

  /**
   * POST /api/v1/safety/sos
   * Any authenticated user can trigger an SOS.
   * Immediately broadcasts a real-time alert to all connected admins.
   */
  @Post('sos')
  async triggerSOS(
    @Req() req: AuthenticatedRequest,
    @Body() body: { tripId?: string; lat?: number; lng?: number },
  ) {
    return this.safetyService.triggerSOS(
      req.user.userId,
      body.tripId,
      body.lat !== undefined && body.lng !== undefined
        ? { lat: body.lat, lng: body.lng }
        : undefined,
    );
  }

  // ===== Emergency Contacts =====

  @Get('contacts')
  async getContacts(@Req() req: AuthenticatedRequest) {
    return this.safetyService.getContacts(req.user.userId);
  }

  @Post('contacts')
  async addContact(
    @Req() req: AuthenticatedRequest,
    @Body() body: { name: string; phoneNumber: string; relationship?: string },
  ) {
    return this.safetyService.addContact(req.user.userId, body);
  }

  @Delete('contacts/:id')
  async deleteContact(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    return this.safetyService.deleteContact(id, req.user.userId);
  }
}
