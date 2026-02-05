import { SetMetadata } from '@nestjs/common';
import { Permission } from '../rbac/rbac.service';

export const PERMISSIONS_KEY = 'permissions';
export const RequirePermissions = (...permissions: Permission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
