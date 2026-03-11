import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { CancellationsService } from './cancellations.service';
import { JwtAuthGuard } from '../Authentication/auth/jwt-auth.guard';
import { Roles } from '../Authentication/common/roles.decorator';
import { RolesGuard } from '../Authentication/common/roles.guard';
import { UserRole } from '../Authentication/users/user.entity';
import { AuthenticatedRequest } from '../Authentication/common/authenticated-request.interface';
import { CancelTripDto } from './dto/cancel.dto';

@Controller('api/v1/cancellations')
@UseGuards(JwtAuthGuard)
export class CancellationsController {
    constructor(private readonly cancellationsService: CancellationsService) { }

    @Post('rider')
    @Roles(UserRole.RIDER)
    @UseGuards(RolesGuard)
    async cancelByRider(@Req() req: AuthenticatedRequest, @Body() dto: CancelTripDto) {
        return this.cancellationsService.cancelByRider(req.user.userId, dto);
    }

    @Post('driver')
    @Roles(UserRole.DRIVER)
    @UseGuards(RolesGuard)
    async cancelByDriver(@Req() req: AuthenticatedRequest, @Body() dto: CancelTripDto) {
        return this.cancellationsService.cancelByDriver(req.user.userId, dto);
    }
}
