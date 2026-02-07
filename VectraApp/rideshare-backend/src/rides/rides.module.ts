import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RidesService } from './rides.service';
import { RidesController } from './rides.controller';
import { RideRequest } from './entities/ride-request.entity';
import { User } from '../users/user.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([RideRequest, User]),
        AuthModule,
    ],
    controllers: [RidesController],
    providers: [RidesService],
    exports: [RidesService],
})
export class RidesModule { }
