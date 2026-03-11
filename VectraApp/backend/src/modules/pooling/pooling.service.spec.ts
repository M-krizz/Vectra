import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { PoolingService } from './pooling.service';
import { PoolGroupEntity, PoolStatus } from './pool-group.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { RideRequestStatus, RideType, VehicleType } from '../ride_requests/ride-request.enums';
import { TripEntity, TripStatus } from '../trips/trip.entity';
import { TripRiderEntity, TripRiderStatus } from '../trips/trip-rider.entity';

// ── Helpers ────────────────────────────────────────────────────────────────

const makeRequest = (overrides: Partial<RideRequestEntity> = {}): RideRequestEntity =>
  ({
    id:           'req-uuid-1',
    riderUserId:  'user-uuid-1',
    pickupPoint:  { type: 'Point', coordinates: [76.9558, 11.0168] },
    dropPoint:    { type: 'Point', coordinates: [76.9629, 11.0025] },
    pickupAddress: 'RS Puram',
    dropAddress:   'Gandhipuram',
    rideType:     RideType.POOL,
    vehicleType:  VehicleType.AUTO,
    status:       RideRequestStatus.REQUESTED,
    poolGroupId:  null,
    requestedAt:  new Date(),
    expiresAt:    null,
    ...overrides,
  } as RideRequestEntity);

const makeRepo = () => ({
  findOne:            jest.fn(),
  find:               jest.fn(),
  create:             jest.fn(),
  save:               jest.fn(),
  createQueryBuilder: jest.fn(),
});

// ── QueryRunner mock ────────────────────────────────────────────────────────
// Mocks the DataSource.createQueryRunner() flow used in finalizePool

const makeQueryRunner = (overrides: Partial<Record<string, jest.Mock>> = {}) => {
  const manager = {
    createQueryBuilder: jest.fn(),
    save:               jest.fn(),
  };
  return {
    connect:             jest.fn(),
    startTransaction:    jest.fn(),
    commitTransaction:   jest.fn(),
    rollbackTransaction: jest.fn(),
    release:             jest.fn(),
    manager,
    ...overrides,
  };
};

// ── Tests ──────────────────────────────────────────────────────────────────

describe('PoolingService', () => {
  let service: PoolingService;
  let requestRepo:   ReturnType<typeof makeRepo>;
  let poolGroupRepo: ReturnType<typeof makeRepo>;
  let tripRepo:      ReturnType<typeof makeRepo>;
  let tripRiderRepo: ReturnType<typeof makeRepo>;
  let dataSource:    jest.Mocked<Pick<DataSource, 'createQueryRunner'>>;

  beforeEach(async () => {
    requestRepo   = makeRepo();
    poolGroupRepo = makeRepo();
    tripRepo      = makeRepo();
    tripRiderRepo = makeRepo();
    dataSource    = { createQueryRunner: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PoolingService,
        { provide: getRepositoryToken(RideRequestEntity), useValue: requestRepo  },
        { provide: getRepositoryToken(PoolGroupEntity),   useValue: poolGroupRepo },
        { provide: getRepositoryToken(TripEntity),        useValue: tripRepo       },
        { provide: getRepositoryToken(TripRiderEntity),   useValue: tripRiderRepo  },
        { provide: DataSource,                            useValue: dataSource     },
      ],
    }).compile();

    service = module.get<PoolingService>(PoolingService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── findCandidates ────────────────────────────────────────────────────────

  describe('findCandidates', () => {
    it('immediately returns empty array for BIKE vehicle type (bikes do not pool)', async () => {
      const bikeRequest = makeRequest({ vehicleType: VehicleType.BIKE });
      const result = await service.findCandidates(bikeRequest, 500);
      expect(result).toEqual([]);
      expect(requestRepo.createQueryBuilder).not.toHaveBeenCalled();
    });

    it('calls query builder with correct status, rideType, vehicleType, and radius filters', async () => {
      const request = makeRequest({ vehicleType: VehicleType.AUTO });

      const qb = {
        where:    jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy:  jest.fn().mockReturnThis(),
        limit:    jest.fn().mockReturnThis(),
        getMany:  jest.fn().mockResolvedValue([]),
      };
      requestRepo.createQueryBuilder.mockReturnValue(qb);

      await service.findCandidates(request, 1000);

      expect(requestRepo.createQueryBuilder).toHaveBeenCalledWith('request');
      // Status filter
      expect(qb.where).toHaveBeenCalledWith('request.status = :status', {
        status: RideRequestStatus.REQUESTED,
      });
      // Vehicle type filter
      expect(qb.andWhere).toHaveBeenCalledWith('request.vehicle_type = :vehicleType', {
        vehicleType: VehicleType.AUTO,
      });
      // Excludes the request itself
      expect(qb.andWhere).toHaveBeenCalledWith('request.id != :selfId', { selfId: request.id });
    });

    it('returns candidates from the query builder result', async () => {
      const request    = makeRequest({ vehicleType: VehicleType.AUTO });
      const candidates = [
        makeRequest({ id: 'req-uuid-2', riderUserId: 'user-uuid-2' }),
        makeRequest({ id: 'req-uuid-3', riderUserId: 'user-uuid-3' }),
      ];

      const qb = {
        where:    jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy:  jest.fn().mockReturnThis(),
        limit:    jest.fn().mockReturnThis(),
        getMany:  jest.fn().mockResolvedValue(candidates),
      };
      requestRepo.createQueryBuilder.mockReturnValue(qb);

      const result = await service.findCandidates(request, 500);
      expect(result).toHaveLength(2);
      expect(result[0].id).toBe('req-uuid-2');
    });
  });

  // ── evaluateGroupings ──────────────────────────────────────────────────────

  describe('evaluateGroupings', () => {
    it('returns null immediately when there are no candidates', async () => {
      const result = await service.evaluateGroupings(makeRequest(), []);
      expect(result).toBeNull();
    });

    it('returns a grouping with isValid=true and the correct riders', async () => {
      const main       = makeRequest({ id: 'req-uuid-1' });
      const candidates = [makeRequest({ id: 'req-uuid-2', riderUserId: 'user-uuid-2' })];

      const result = await service.evaluateGroupings(main, candidates);

      expect(result).not.toBeNull();
      expect(result?.isValid).toBe(true);
      expect(result?.detourOk).toBe(true);
      expect(result?.riders).toContainEqual(expect.objectContaining({ id: 'req-uuid-1' }));
      expect(result?.riders).toContainEqual(expect.objectContaining({ id: 'req-uuid-2' }));
    });

    it('caps AUTO at 3 total riders max', async () => {
      const main       = makeRequest({ vehicleType: VehicleType.AUTO });
      // Supply 5 candidates — only 2 should be taken (1 main + 2 = 3 total)
      const candidates = Array.from({ length: 5 }, (_, i) =>
        makeRequest({ id: `req-uuid-${i + 2}`, riderUserId: `user-uuid-${i + 2}` }),
      );

      const result = await service.evaluateGroupings(main, candidates);
      expect(result?.riders).toHaveLength(3);
    });

    it('caps CAB at 4 total riders max', async () => {
      const main       = makeRequest({ vehicleType: VehicleType.CAB });
      const candidates = Array.from({ length: 5 }, (_, i) =>
        makeRequest({ id: `req-uuid-${i + 2}`, vehicleType: VehicleType.CAB, riderUserId: `user-uuid-${i + 2}` }),
      );

      const result = await service.evaluateGroupings(main, candidates);
      expect(result?.riders).toHaveLength(4);
    });
  });

  // ── finalizePool ───────────────────────────────────────────────────────────

  describe('finalizePool', () => {
    const setupSuccessfulQueryRunner = () => {
      const rider1 = makeRequest({ id: 'req-uuid-1' });
      const rider2 = makeRequest({ id: 'req-uuid-2', riderUserId: 'user-uuid-2' });

      const poolGroup:  PoolGroupEntity  = { id: 'pool-uuid-1', status: PoolStatus.FORMING, vehicleType: VehicleType.AUTO, currentRidersCount: 2, maxRiders: 3 } as any;
      const savedTrip:  TripEntity       = { id: 'trip-uuid-1', status: TripStatus.REQUESTED } as any;
      const tripRider:  TripRiderEntity  = { tripId: 'trip-uuid-1', riderUserId: 'user-uuid-1', status: TripRiderStatus.JOINED } as any;

      const qb = {
        setLock:   jest.fn().mockReturnThis(),
        whereInIds: jest.fn().mockReturnThis(),
        andWhere:  jest.fn().mockReturnThis(),
        getMany:   jest.fn().mockResolvedValue([rider1, rider2]),
      };

      const qr = makeQueryRunner();
      qr.manager.createQueryBuilder.mockReturnValue(qb);
      qr.manager.save
        .mockResolvedValueOnce(poolGroup)   // PoolGroupEntity
        .mockResolvedValue(savedTrip);      // TripEntity + TripRiderEntities

      poolGroupRepo.create.mockReturnValue(poolGroup);
      tripRepo.create.mockReturnValue(savedTrip);
      tripRiderRepo.create.mockReturnValue(tripRider);

      dataSource.createQueryRunner.mockReturnValue(qr as any);

      return { qr, rider1, rider2 };
    };

    it('commits the transaction and returns the trip id on success', async () => {
      const { qr, rider1, rider2 } = setupSuccessfulQueryRunner();

      const tripId = await service.finalizePool({ riders: [rider1, rider2] });

      expect(qr.startTransaction).toHaveBeenCalled();
      expect(qr.commitTransaction).toHaveBeenCalled();
      expect(qr.rollbackTransaction).not.toHaveBeenCalled();
      expect(typeof tripId).toBe('string');
    });

    it('always releases the query runner even on success', async () => {
      const { qr, rider1, rider2 } = setupSuccessfulQueryRunner();
      await service.finalizePool({ riders: [rider1, rider2] });
      expect(qr.release).toHaveBeenCalled();
    });

    it('rolls back and returns null when locked row count does not match (double-pool prevention)', async () => {
      const rider1 = makeRequest({ id: 'req-uuid-1' });
      const rider2 = makeRequest({ id: 'req-uuid-2' });

      const qb = {
        setLock:    jest.fn().mockReturnThis(),
        whereInIds: jest.fn().mockReturnThis(),
        andWhere:   jest.fn().mockReturnThis(),
        // Only 1 row locked instead of 2
        getMany: jest.fn().mockResolvedValue([rider1]),
      };

      const qr = makeQueryRunner();
      qr.manager.createQueryBuilder.mockReturnValue(qb);
      dataSource.createQueryRunner.mockReturnValue(qr as any);

      const result = await service.finalizePool({ riders: [rider1, rider2] });

      expect(qr.rollbackTransaction).toHaveBeenCalled();
      expect(qr.commitTransaction).not.toHaveBeenCalled();
      expect(result).toBeNull();
    });

    it('rolls back and re-throws on unexpected DB error', async () => {
      const rider1 = makeRequest({ id: 'req-uuid-1' });

      const qb = {
        setLock:    jest.fn().mockReturnThis(),
        whereInIds: jest.fn().mockReturnThis(),
        andWhere:   jest.fn().mockReturnThis(),
        getMany:    jest.fn().mockRejectedValue(new Error('DB timeout')),
      };

      const qr = makeQueryRunner();
      qr.manager.createQueryBuilder.mockReturnValue(qb);
      dataSource.createQueryRunner.mockReturnValue(qr as any);

      await expect(service.finalizePool({ riders: [rider1] })).rejects.toThrow('DB timeout');
      expect(qr.rollbackTransaction).toHaveBeenCalled();
      expect(qr.release).toHaveBeenCalled();
    });
  });
});
