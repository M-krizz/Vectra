import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  UseGuards,
  Req,
  Patch,
} from '@nestjs/common';
import { SafetyService } from './safety.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { RequirePermissions } from '../Authentication/common/permissions.decorator';
import { PermissionsGuard } from '../Authentication/common/permissions.guard';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';
import { Permission } from '../Authentication/rbac/rbac.service';

interface ReportIncidentDto {
  description: string;
  rideId?: string;
}

interface ResolveIncidentDto {
  resolution: string;
}

@Controller('api/v1/safety')
@UseGuards(JwtAuthGuard)
export class SafetyController {
  constructor(private readonly safetyService: SafetyService) {}

  @Post('incidents')
  async reportIncident(
    @Req() req: AuthenticatedRequest,
    @Body() body: ReportIncidentDto,
  ) {
    // TODO: If rideId provided, fetch ride and pass to service
    return this.safetyService.reportIncident(
      req.user as any, // Will be properly typed in implementation
      body.description,
    );
  }

  @Get('incidents')
  @RequirePermissions(Permission.INCIDENT_RESOLVE)
  @UseGuards(PermissionsGuard)
  async listIncidents() {
    return this.safetyService.listIncidents();
  }

  @Patch('incidents/:id/resolve')
  @RequirePermissions(Permission.INCIDENT_RESOLVE)
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

  @Get('incidents/:id')
  @RequirePermissions(Permission.INCIDENT_VIEW)
  @UseGuards(PermissionsGuard)
  async getIncident(@Param('id') id: string) {
    return this.safetyService.getIncident(id);
  }
}