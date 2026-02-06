import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE } from '@nestjs/core';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import * as dotenv from 'dotenv';

// Global modules
import { RedisModule } from './integrations/redis/redis.module';

// Authentication module (merged)
import { AuthenticationModule } from './modules/Authentication';

// Feature modules
import { RideRequestsModule } from './modules/ride_requests/ride-requests.module';
import { TripsModule } from './modules/trips/trips.module';

dotenv.config();

@Module({
  imports: [
    // Global Redis connection
    RedisModule,

    // Scheduling for cron jobs
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

    // Authentication (users, drivers, admin, rbac, profile, compliance)
    AuthenticationModule,

    // Ride modules
    RideRequestsModule,
    TripsModule,
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
export class AppModule {}
