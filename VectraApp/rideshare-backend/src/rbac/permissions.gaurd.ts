import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from './permissions.decorator';
import { RbacService } from './rbac.service';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private reflector: Reflector, private rbac: RbacService) {}

  canActivate(context: ExecutionContext): boolean {
    const required: string[] = this.reflector.getAllAndOverride<string[]>(PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) {
      // no permission required -> allow
      return true;
    }

    const req = context.switchToHttp().getRequest();
    const user = req.user;
    if (!user) return false;

    // user.role is expected to be the primary role string (RIDER/DRIVER/ADMIN/COMMUNITY_ADMIN)
    const role = user.role;
    if (!role) return false;

    // check all required permissions are present for user's role
    for (const perm of required) {
      if (!this.rbac.hasPermission(role, perm as any)) {
        return false;
      }
    }
    return true;
  }
}
