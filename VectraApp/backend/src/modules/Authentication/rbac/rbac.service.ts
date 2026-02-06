import { Injectable, Logger } from '@nestjs/common';

/**
 * Permission types for RBAC
 */
export type Permission =
  | 'ride:book'
  | 'ride:see_requests'
  | 'ride:accept'
  | 'profile:view'
  | 'profile:edit'
  | 'payments:view'
  | 'carbon:dashboard'
  | 'navigation:use'
  | 'earnings:view'
  | 'availability:toggle'
  | 'user:manage'
  | 'system:config'
  | 'incident:resolve'
  | 'financial:view'
  | 'fare:adjust'
  | 'user:suspend'
  | 'payout:process'
  | 'leaderboard:manage';

@Injectable()
export class RbacService {
  private readonly logger = new Logger(RbacService.name);

  public static readonly Roles = {
    RIDER: 'RIDER',
    DRIVER: 'DRIVER',
    ADMIN: 'ADMIN',
    COMMUNITY_ADMIN: 'COMMUNITY_ADMIN',
  } as const;

  private readonly rolePermissions: Record<string, Permission[]> = {
    [RbacService.Roles.RIDER]: [
      'ride:book',
      'profile:view',
      'profile:edit',
      'payments:view',
      'carbon:dashboard',
    ],
    [RbacService.Roles.DRIVER]: [
      'ride:see_requests',
      'ride:accept',
      'navigation:use',
      'earnings:view',
      'availability:toggle',
      'profile:view',
      'profile:edit',
    ],
    [RbacService.Roles.ADMIN]: [
      'user:manage',
      'system:config',
      'incident:resolve',
      'financial:view',
      'fare:adjust',
      'user:suspend',
      'payout:process',
      'profile:view',
    ],
    [RbacService.Roles.COMMUNITY_ADMIN]: [
      'leaderboard:manage',
      'carbon:dashboard',
      'profile:view',
    ],
  };

  hasPermission(role: string, permission: Permission): boolean {
    const perms = this.rolePermissions[role] ?? [];
    return perms.includes(permission);
  }

  getPermissionsForRoles(roles: string[] | string): Permission[] {
    const roleList = Array.isArray(roles) ? roles : [roles];
    const perms = new Set<Permission>();
    for (const r of roleList) {
      (this.rolePermissions[r] ?? []).forEach((p) => perms.add(p));
    }
    return Array.from(perms);
  }

  getAllRoles(): string[] {
    return Object.keys(this.rolePermissions);
  }

  setRolePermissions(role: string, perms: Permission[]) {
    this.logger.warn(`Setting permissions for role ${role} — in-memory only.`);
    this.rolePermissions[role] = perms;
  }
}
