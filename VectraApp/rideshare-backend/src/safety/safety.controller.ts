import { Controller, Post, Body, Get, Param, UseGuards, Req } from '@nestjs/common';
import { SafetyService } from './safety.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PermissionsGuard } from '../rbac/permissions.gaurd';
import { Permissions } from '../rbac/permissions.decorator';

@Controller('safety')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SafetyController {
    constructor(private readonly safetyService: SafetyService) { }

    @Post('report')
    async reportIncident(@Req() req: any, @Body() body: { description: string; rideId?: string }) {
        return this.safetyService.reportIncident(req.user, body.description);
    }

    @Get('incidents')
    @Permissions('incident:resolve')
    async listIncidents() {
        return this.safetyService.listIncidents();
    }

    @Post('incidents/:id/resolve')
    @Permissions('incident:resolve')
    async resolveIncident(@Param('id') id: string, @Body() body: { resolution: string }) {
        return this.safetyService.resolveIncident(id, body.resolution);
    }
}
