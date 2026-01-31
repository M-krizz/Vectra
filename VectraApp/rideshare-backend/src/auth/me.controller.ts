import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RbacService } from '../rbac/rbac.service';

/**
 * Mobile client endpoint to fetch current user's role & permissions
 * GET /auth/me/permissions
 */
@Controller('auth/me')
export class MeController {
  constructor(private readonly rbac: RbacService) {}

  @UseGuards(JwtAuthGuard)
  @Get('permissions')
  async getMyPermissions(@Req() req: any) {
    const user = req.user;
    const role = user?.role ?? null;
    const permissions = role ? this.rbac.getPermissionsForRoles(role) : [];
    return { status: 'ok', user: { id: user.id, role }, permissions };
  }
}
