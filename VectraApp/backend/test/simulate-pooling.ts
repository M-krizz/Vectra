import { DataSource, Repository } from 'typeorm';
import { UserEntity, UserRole, AccountStatus } from '../src/modules/Authentication/users/user.entity';
import { RideRequestEntity } from '../src/modules/ride_requests/ride-request.entity';
import { PoolGroupEntity } from '../src/modules/pooling/pool-group.entity';
import { TripEntity } from '../src/modules/trips/trip.entity';
import { TripRiderEntity } from '../src/modules/trips/trip-rider.entity';
import { RideRequestStatus, RideType, VehicleType } from '../src/modules/ride_requests/ride-request.enums';
import { PoolingService } from '../src/modules/pooling/pooling.service';
import { PoolingManager } from '../src/modules/pooling/pooling.manager';
import * as dotenv from 'dotenv';
import { GeoPoint } from '../src/common/types/geo-point.type';

dotenv.config();

/**
 * SIMULATION SCRIPT FOR POOLING V1
 */
async function runSimulation() {
    console.log('--- Starting Pooling Simulation (Manual Execution) ---');

    const SimulationDataSource = new DataSource({
        type: 'postgres',
        host: process.env.DB_HOST,
        port: Number(process.env.DB_PORT || 5432),
        username: process.env.DB_USER,
        password: process.env.DB_PASS,
        database: process.env.DB_NAME,
        entities: ['src/**/*.entity.ts'],
        synchronize: false,
        logging: false
    });

    try {
        await SimulationDataSource.initialize();
        console.log('Database Connected.');

        const userRepo: Repository<UserEntity> = SimulationDataSource.getRepository(UserEntity);
        const requestRepo: Repository<RideRequestEntity> = SimulationDataSource.getRepository(RideRequestEntity);
        const poolRepo: Repository<PoolGroupEntity> = SimulationDataSource.getRepository(PoolGroupEntity);
        const tripRepo: Repository<TripEntity> = SimulationDataSource.getRepository(TripEntity);
        const tripRiderRepo: Repository<TripRiderEntity> = SimulationDataSource.getRepository(TripRiderEntity);

        // --- INSTANTIATE SERVICES MANUALLY ---
        const poolingService = new PoolingService(
            requestRepo,
            poolRepo,
            tripRepo,
            tripRiderRepo,
            SimulationDataSource
        );
        const poolingManager = new PoolingManager(
            requestRepo,
            poolingService
        );

        // 1. Create Riders
        console.log('Creating Test Riders...');
        const riderA: UserEntity = await createOrGetUser(userRepo, 'rider_a_sim@test.com', 'Rider A Sim');
        const riderB: UserEntity = await createOrGetUser(userRepo, 'rider_b_sim@test.com', 'Rider B Sim');

        // 2. Create Requests
        const pickup: GeoPoint = { type: 'Point', coordinates: [77.6412, 12.9716] };
        const drop: GeoPoint = { type: 'Point', coordinates: [77.6350, 12.9200] };

        console.log('Creating Ride Requests (POOL, AUTO)...');

        await requestRepo.delete({ riderUserId: riderA.id });
        await requestRepo.delete({ riderUserId: riderB.id });

        const reqA = requestRepo.create({
            riderUserId: riderA.id,
            pickupPoint: pickup,
            dropPoint: drop,
            pickupAddress: 'Indiranagar 100ft Road',
            dropAddress: 'Koramangala Sony Signal',
            rideType: RideType.POOL,
            vehicleType: VehicleType.AUTO,
            status: RideRequestStatus.REQUESTED,
        });
        const savedReqA = await requestRepo.save(reqA);
        console.log(`Request A Created: ${savedReqA.id}`);

        const reqB = requestRepo.create({
            riderUserId: riderB.id,
            pickupPoint: pickup,
            dropPoint: drop,
            pickupAddress: 'Indiranagar KFC',
            dropAddress: 'Koramangala Wipro Park',
            rideType: RideType.POOL,
            vehicleType: VehicleType.AUTO,
            status: RideRequestStatus.REQUESTED,
        });
        const savedReqB = await requestRepo.save(reqB);
        console.log(`Request B Created: ${savedReqB.id}`);

        // DEBUGGING
        console.log('--- Debugging Data ---');
        console.log('ReqA Pickup:', JSON.stringify(savedReqA.pickupPoint));
        const rawMatches = await requestRepo
            .createQueryBuilder('request')
            .where('request.status = :status', { status: RideRequestStatus.REQUESTED })
            .andWhere('request.ride_type = :rideType', { rideType: RideType.POOL })
            .andWhere('request.vehicle_type = :vehicleType', { vehicleType: VehicleType.AUTO })
            .andWhere('request.id != :selfId', { selfId: savedReqA.id })
            .andWhere(
                `ST_DWithin(request.pickup_point, ST_SetSRID(ST_GeomFromGeoJSON(:pickupPoint), 4326)::geography, :radius)`,
                {
                    pickupPoint: JSON.stringify(pickup),
                    radius: 1000,
                },
            )
            .getMany();
        console.log(`Manual Spatial Check Found: ${rawMatches.length} candidates (Radius 1000m)`);
        rawMatches.forEach(m => console.log('Candidate ID:', m.id));

        // 3. EXECUTE POOLING LOGIC MANUALLY
        console.log('\n--- Executing Pooling Logic Manually ---');
        await poolingManager.handlePoolingLoop(); // Run the loop ONCE
        console.log('Pooling Loop Completed.');

        // 4. Verify
        console.log('\n--- Verifying Results ---');

        const reloadA = await requestRepo.findOne({ where: { id: savedReqA.id } });
        const reloadB = await requestRepo.findOne({ where: { id: savedReqB.id } });

        if (!reloadA || !reloadB) {
            console.error('❌ FAILURE: Could not reload requests.');
            return;
        }

        console.log(`Request A Status: ${reloadA.status} | PoolID: ${reloadA.poolGroupId}`);
        console.log(`Request B Status: ${reloadB.status} | PoolID: ${reloadB.poolGroupId}`);

        if (reloadA.status === RideRequestStatus.POOLED && reloadB.status === RideRequestStatus.POOLED) {
            console.log('✅ SUCCESS: Both requests are POOLED.');

            if (reloadA.poolGroupId && reloadA.poolGroupId === reloadB.poolGroupId) {
                console.log(`✅ SUCCESS: Both belong to same Pool Group: ${reloadA.poolGroupId}`);

                const pool = await poolRepo.findOne({ where: { id: reloadA.poolGroupId } });
                console.log(`   Pool Status: ${pool?.status} | Riders: ${pool?.currentRidersCount}`);

                const tripRiderEntry = await tripRiderRepo.findOne({ where: { riderUserId: riderA.id } });
                if (tripRiderEntry) {
                    const trip = await tripRepo.findOne({ where: { id: tripRiderEntry.tripId } });
                    console.log(`✅ SUCCESS: Trip Created: ${trip?.id} | Status: ${trip?.status}`);
                } else {
                    console.error('❌ FAILURE: No TripRider entry found for Rider A.');
                }

            } else {
                console.error('❌ FAILURE: Requests have different or missing Pool Group IDs.');
            }

        } else {
            console.error('❌ FAILURE: Requests were not pooled.');
        }

    } catch (e) {
        console.error('Simulation Error:', e);
    } finally {
        if (SimulationDataSource.isInitialized) await SimulationDataSource.destroy();
    }
}

async function createOrGetUser(repo: Repository<UserEntity>, email: string, name: string): Promise<UserEntity> {
    let user = await repo.findOne({ where: { email } });
    if (!user) {
        user = repo.create({
            email,
            fullName: name,
            phone: Math.floor(Math.random() * 9000000000 + 1000000000).toString(),
            role: UserRole.RIDER,
            status: AccountStatus.ACTIVE,
            isVerified: true
        });
        await repo.save(user);
    }
    return user;
}

runSimulation().catch(err => {
    console.error('Unhandled simulation error:', err);
    process.exit(1);
});
