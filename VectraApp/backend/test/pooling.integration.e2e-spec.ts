import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { PoolingService } from '../src/modules/pooling/pooling.service';
import { PoolGroupEntity, PoolStatus } from '../src/modules/pooling/pool-group.entity';
import { RideRequestEntity } from '../src/modules/ride_requests/ride-request.entity';
import { RideRequestStatus, RideType, VehicleType } from '../src/modules/ride_requests/ride-request.enums';
import { TripEntity, TripStatus } from '../src/modules/trips/trip.entity';
import { TripRiderEntity, TripRiderStatus } from '../src/modules/trips/trip-rider.entity';

describe('Pooling Integration (Service -> Transaction -> Multiple Repos)', () => {
  let service: PoolingService;
  let dataSource: any;
  let requestRepo: any;
  let poolGroupRepo: any;
  let tripRepo: any;
  let tripRiderRepo: any;

  let mockQueryRunner: any;
  let mockDataSource: any;
  let mockRepo: any;

  beforeEach(async () => {
    mockQueryRunner = {
      connect: jest.fn(),
      startTransaction: jest.fn(),
      commitTransaction: jest.fn(),
      rollbackTransaction: jest.fn(),
      release: jest.fn(),
      manager: {
        createQueryBuilder: jest.fn(),
        save: jest.fn(),
      },
    };

    mockDataSource = {
      createQueryRunner: jest.fn().mockReturnValue(mockQueryRunner),
    };

    mockRepo = {
      create: jest.fn().mockImplementation((dto) => dto),
      save: jest.fn(),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PoolingService,
        { provide: DataSource, useValue: mockDataSource },
        { provide: getRepositoryToken(RideRequestEntity), useValue: mockRepo },
        { provide: getRepositoryToken(PoolGroupEntity), useValue: mockRepo },
        { provide: getRepositoryToken(TripEntity), useValue: mockRepo },
        { provide: getRepositoryToken(TripRiderEntity), useValue: mockRepo },
      ],
    }).compile();

    service = module.get<PoolingService>(PoolingService);
    dataSource = module.get(DataSource);
    requestRepo = module.get(getRepositoryToken(RideRequestEntity));
    poolGroupRepo = module.get(getRepositoryToken(PoolGroupEntity));
    tripRepo = module.get(getRepositoryToken(TripEntity));
    tripRiderRepo = module.get(getRepositoryToken(TripRiderEntity));
  });

  afterEach(() => {
    jest.clearAllMocks();
    mockRepo.create.mockClear();
    mockRepo.save.mockClear();
  });

  describe('Finalize Pool Transaction', () => {
    it('INT-POOL-001: Successfully finalizes pool -> creates PoolGroup, Trip, updates requests, and commits transaction', async () => {
      const rider1 = { id: 'req-1', vehicleType: VehicleType.AUTO, status: RideRequestStatus.REQUESTED, pickupPoint: {}, dropPoint: {}, riderUserId: 'user-1' } as RideRequestEntity;
      const rider2 = { id: 'req-2', vehicleType: VehicleType.AUTO, status: RideRequestStatus.REQUESTED, pickupPoint: {}, dropPoint: {}, riderUserId: 'user-2' } as RideRequestEntity;
      
      // Mock the pessimistic lock query wrapper
      const mockQueryBuilder = {
        setLock: jest.fn().mockReturnThis(),
        whereInIds: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([rider1, rider2]),
      };
      mockQueryRunner.manager.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      // Mock consecutive saves in the transaction
      // 1. Save PoolGroup
      mockQueryRunner.manager.save.mockResolvedValueOnce({ id: 'pool-123' })
      // 2. Save Request 1 (status POOLED)
      .mockResolvedValueOnce(rider1)
      // 3. Save Request 2 (status POOLED)
      .mockResolvedValueOnce(rider2)
      // 4. Save Trip
      .mockResolvedValueOnce({ id: 'trip-123' })
      // 5,6. Save TripRiders
      .mockResolvedValueOnce({ id: 'tr-1' })
      .mockResolvedValueOnce({ id: 'tr-2' });

      const tripId = await service.finalizePool({ riders: [rider1, rider2] });

      expect(tripId).toEqual('trip-123');

      // Verify Transaction lifecycle
      expect(mockQueryRunner.startTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
      expect(mockQueryRunner.rollbackTransaction).not.toHaveBeenCalled();

      // Verify state updates
      expect(poolGroupRepo.create).toHaveBeenCalledWith(expect.objectContaining({ status: PoolStatus.FORMING, currentRidersCount: 2 }));
      expect(tripRepo.create).toHaveBeenCalledWith(expect.objectContaining({ status: TripStatus.REQUESTED }));
      expect(rider1.status).toEqual(RideRequestStatus.POOLED);
      expect(poolGroupRepo.create).toHaveBeenCalledWith(expect.objectContaining({ status: PoolStatus.FORMING, currentRidersCount: 2 }));
      expect(tripRepo.create).toHaveBeenCalledWith(expect.objectContaining({ status: TripStatus.REQUESTED }));
      expect(rider1.status).toEqual(RideRequestStatus.POOLED);
      expect(rider2.status).toEqual(RideRequestStatus.POOLED);
      // It gets called once per rider (2 riders), but due to testing module scoping, 
      // check if it's called with the correct arguments rather than absolute times, 
      // or clear it first.
      expect(tripRiderRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        tripId: 'trip-123',
        riderUserId: 'user-1',
      }));
      expect(tripRiderRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        tripId: 'trip-123',
        riderUserId: 'user-2',
      }));
    });

    it('INT-POOL-002: Thwarts double-booking race condition -> rolls back if riders are already snatched', async () => {
      const rider1 = { id: 'req-1' } as RideRequestEntity;
      const rider2 = { id: 'req-2' } as RideRequestEntity;
      
      // Simulation: Query builder tries to lock 2 rows, but only 1 is returned (one was just taken by another process)
      const mockQueryBuilder = {
        setLock: jest.fn().mockReturnThis(),
        whereInIds: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([rider1]), // Only 1 returned
      };
      mockQueryRunner.manager.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const tripId = await service.finalizePool({ riders: [rider1, rider2] });

      expect(tripId).toBeNull();
      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.commitTransaction).not.toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });

    it('INT-POOL-003: Rolls back transaction completely if any DB save fails', async () => {
      const rider1 = { id: 'req-1', vehicleType: VehicleType.AUTO } as RideRequestEntity;
      
      const mockQueryBuilder = {
        setLock: jest.fn().mockReturnThis(),
        whereInIds: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([rider1]),
      };
      mockQueryRunner.manager.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      // Simulate a DB failure mid-transaction (e.g. creating Trip fails)
      mockQueryRunner.manager.save.mockRejectedValue(new Error('DB connection lost'));

      await expect(service.finalizePool({ riders: [rider1] })).rejects.toThrow('DB connection lost');

      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });
  });
});
