import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { RideRequestsService } from './ride-requests.service';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UserEntity } from '../users/user.entity';

@Controller('ride-requests')
@UseGuards(JwtAuthGuard)
export class RideRequestsController {
    constructor(private readonly rideRequestsService: RideRequestsService) { }

    @Post()
    async create(@Req() req: any, @Body() dto: CreateRideRequestDto) {
        // req.user is populated by JwtStrategy
        const user = req.user as UserEntity;
        return await this.rideRequestsService.createRequest(user, dto);
    }
}
