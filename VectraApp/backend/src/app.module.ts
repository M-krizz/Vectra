import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import * as dotenv from 'dotenv';

import { ScheduleModule } from '@nestjs/schedule';

// Global modules
import { RedisModule } from './integrations/redis/redis.module';

// Feature modules
import { UsersModule } from './modules/users/users.module';
import { DriversModule } from './modules/drivers/drivers.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { RideRequestsModule } from './modules/ride_requests/ride-requests.module';
import { TripsModule } from './modules/trips/trips.module';
import { AdminModule } from './modules/admin/admin.module';
import { AuthModule } from './modules/auth/auth.module';
import { ChatModule } from './modules/chat/chat.module';

dotenv.config();

@Module({
    imports: [
        // Global Redis connection
        RedisModule,

        // Cron Scheduling
        ScheduleModule.forRoot(),

        // Database connection
        TypeOrmModule.forRoot({
            type: 'postgres',
            host: process.env.DB_HOST,
            port: Number(process.env.DB_PORT || 5432),
            username: process.env.DB_USER,
            password: process.env.DB_PASS,
            database: process.env.DB_NAME,
            autoLoadEntities: true,
            synchronize: false, // ✅ IMPORTANT: migrations control the schema
        }),

        // Feature modules
        AuthModule,
        UsersModule,
        DriversModule,
        VehiclesModule,
        RideRequestsModule,
        TripsModule,
        AdminModule,
        ChatModule,
    ],
    controllers: [],
    providers: [
        // Global validation pipe for DTOs
        {
            provide: APP_PIPE,
            useValue: new ValidationPipe({
                whitelist: true,
                forbidNonWhitelisted: true,
                transform: true,
            }),
        },
    ],
})
export class AppModule { }
