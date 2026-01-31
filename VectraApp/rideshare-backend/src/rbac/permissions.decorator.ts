import { SetMetadata } from '@nestjs/common';
import { Permission } from './permissions.enum';

export const PERMISSIONS_KEY = 'permissions';
export const Permissions = (...perms: Permission[]) => SetMetadata(PERMISSIONS_KEY, perms);
