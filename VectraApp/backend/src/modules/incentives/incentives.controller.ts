import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { IncentivesService } from './incentives.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { RolesGuard } from '../Authentication/common/roles.guard';
import { UserRole } from '../Authentication/users/user.entity';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';

@Controller('api/v1/incentives')
@UseGuards(JwtAuthGuard)
export class IncentivesController {
    constructor(private readonly incentivesService: IncentivesService) { }

    /** GET /api/v1/incentives — all incentives for the driver */
    @Get()
    @Roles(UserRole.DRIVER)
    @UseGuards(RolesGuard)
    async getAll(@Req() req: AuthenticatedRequest) {
        return this.incentivesService.getAllIncentives(req.user.userId);
    }

    /** GET /api/v1/incentives/active — active non-completed incentives */
    @Get('active')
    @Roles(UserRole.DRIVER)
    @UseGuards(RolesGuard)
    async getActive(@Req() req: AuthenticatedRequest) {
        return this.incentivesService.getActiveIncentives(req.user.userId);
    }

    /** GET /api/v1/incentives/completed — completed incentives */
    @Get('completed')
    @Roles(UserRole.DRIVER)
    @UseGuards(RolesGuard)
    async getCompleted(@Req() req: AuthenticatedRequest) {
        return this.incentivesService.getCompletedIncentives(req.user.userId);
    }
}
