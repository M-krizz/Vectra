import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { RbacService } from '../../rbac/rbac.service';

export class ChangeRoleDto {
  @IsIn(['RIDER','DRIVER','ADMIN','COMMUNITY_ADMIN'])
  newRole: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  reason?: string;
}
