import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RbacService, Permission } from '../rbac/rbac.service';
import { PERMISSIONS_KEY } from './permissions.decorator';
import { AuthenticatedRequest } from './authenticated-request.interface';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private rbacService: RbacService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions = this.reflector.getAllAndOverride<Permission[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.user;

    if (!user || !user.role) {
      return false;
    }

    return requiredPermissions.every((permission) =>
      this.rbacService.hasPermission(user.role, permission),
    );
  }
}
