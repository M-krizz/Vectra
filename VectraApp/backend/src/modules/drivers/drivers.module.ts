import { LocationCronService } from './cron/location.cron.ts';

@Module({
    imports: [
        TypeOrmModule.forFeature([DriverProfileEntity, DriverLocationHistoryEntity]),
        RedisModule,
        RideRequestsModule,
    ],
    controllers: [DriversController],
    providers: [DriversService, LocationCronService],
    exports: [DriversService],
})
export class DriversModule { }
