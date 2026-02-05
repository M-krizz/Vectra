import { IsString, IsOptional, IsIn } from 'class-validator';
import { UserRole } from '../../users/user.entity';

export class SuspendUserDto {
  @IsString()
  targetUserId!: string;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class ChangeRoleDto {
  @IsString()
  targetUserId!: string;

  @IsIn(['RIDER', 'DRIVER', 'ADMIN', 'COMMUNITY_ADMIN'])
  newRole!: UserRole;

  @IsOptional()
  @IsString()
  reason?: string;
}
