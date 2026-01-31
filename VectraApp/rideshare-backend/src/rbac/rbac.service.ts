import { Injectable, Logger } from '@nestjs/common';
import { Permission } from './permissions.enum';

/**
 * RbacService
 * - Holds the mapping role -> permissions (fast in-memory).
 * - Exposes helper methods to check permissions, list permissions for role(s).
 *
 * NOTE: For dynamic role management you can persist roles/permissions to DB and seed them,
 * then replace these static mappings with DB reads + cache.
 */
@Injectable()
export class RbacService {
  private readonly logger = new Logger(RbacService.name);

  // canonical list of roles used in the requirements
  public static readonly Roles = {
    RIDER: 'RIDER',
    DRIVER: 'DRIVER',
    ADMIN: 'ADMIN',
    COMMUNITY_ADMIN: 'COMMUNITY_ADMIN',
  } as const;

  // static role -> permission mapping
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
    ],
    [RbacService.Roles.ADMIN]: [
      'user:manage',
      'system:config',
      'incident:resolve',
      'financial:view',
      'fare:adjust',
      'user:suspend',
      'payout:process',
    ],
    [RbacService.Roles.COMMUNITY_ADMIN]: [
      'leaderboard:manage',
      'carbon:dashboard',
      // community admins should not have full user management
    ],
  };

  // returns true if role has a given permission
  hasPermission(role: string, permission: Permission): boolean {
    const perms = this.rolePermissions[role] ?? [];
    return perms.includes(permission);
  }

  // aggregate permissions for multiple roles
  getPermissionsForRoles(roles: string[] | string): Permission[] {
    const roleList = Array.isArray(roles) ? roles : [roles];
    const perms = new Set<Permission>();
    for (const r of roleList) {
      (this.rolePermissions[r] ?? []).forEach(p => perms.add(p));
    }
    return Array.from(perms);
  }

  // list all roles known
  getAllRoles(): string[] {
    return Object.keys(this.rolePermissions);
  }

  // add / update role mapping (in-memory). For admin UI you'd persist this.
  setRolePermissions(role: string, perms: Permission[]) {
    this.logger.warn(`Setting permissions for role ${role} — in-memory only.`);
    this.rolePermissions[role] = perms;
  }
}
