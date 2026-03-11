import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { RideRequestsService } from './ride-requests.service';
import { RideRequestEntity } from './ride-request.entity';
import { RideRequestStatus, RideType, VehicleType } from './ride-request.enums';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';
import { SocketGateway } from '../../realtime/socket.gateway';

// ── Helpers ────────────────────────────────────────────────────────────────

const pickupPoint = { type: 'Point' as const, coordinates: [76.9558, 11.0168] };
const dropPoint   = { type: 'Point' as const, coordinates: [76.9629, 11.0025] };

const makeDto = (overrides: Partial<CreateRideRequestDto> = {}): CreateRideRequestDto => ({
  pickupPoint,
  dropPoint,
  pickupAddress: 'RS Puram, Coimbatore',
  dropAddress:   'Gandhipuram, Coimbatore',
  rideType:      RideType.SOLO,
  vehicleType:   VehicleType.AUTO,
  ...overrides,
});

const makeEntity = (overrides: Partial<RideRequestEntity> = {}): RideRequestEntity =>
  ({
    id:            'req-uuid-1',
    riderUserId:   'user-uuid-1',
    pickupPoint,
    dropPoint,
    pickupAddress: 'RS Puram, Coimbatore',
    dropAddress:   'Gandhipuram, Coimbatore',
    rideType:      RideType.SOLO,
    vehicleType:   VehicleType.AUTO,
    status:        RideRequestStatus.REQUESTED,
    poolGroupId:   null,
    requestedAt:   new Date('2024-06-01T10:00:00Z'),
    expiresAt:     null,
    ...overrides,
  } as RideRequestEntity);

const makeRepo = () => ({
  findOne: jest.fn(),
  find:    jest.fn(),
  create:  jest.fn(),
  save:    jest.fn(),
  update:  jest.fn(),
});

// ── Tests ──────────────────────────────────────────────────────────────────

describe('RideRequestsService', () => {
  let service: RideRequestsService;
  let repo: ReturnType<typeof makeRepo>;

  beforeEach(async () => {
    repo = makeRepo();

    const mockSocketGateway = { emitTripStatus: jest.fn(), emitLocationUpdate: jest.fn() };
    const mockDataSource = {
      createQueryRunner: jest.fn().mockReturnValue({
        connect: jest.fn(),
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
        manager: {
          createQueryBuilder: jest.fn().mockReturnValue({
            setLock: jest.fn().mockReturnThis(),
            where: jest.fn().mockReturnThis(),
            getOne: jest.fn().mockResolvedValue(null),
          }),
          findOne: jest.fn(),
          create: jest.fn(),
          save: jest.fn(),
        },
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RideRequestsService,
        { provide: getRepositoryToken(RideRequestEntity), useValue: repo },
        { provide: SocketGateway, useValue: mockSocketGateway },
        { provide: DataSource, useValue: mockDataSource },
      ],
    }).compile();

    service = module.get<RideRequestsService>(RideRequestsService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── createRequest ────────────────────────────────────────────────────────

  describe('createRequest', () => {
    it('creates a ride request with REQUESTED status and correct fields', async () => {
      const entity = makeEntity();
      repo.create.mockReturnValue(entity);
      repo.save.mockResolvedValue(entity);

      const dto = makeDto();
      const result = await service.createRequest('user-uuid-1', dto);

      expect(repo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          riderUserId:  'user-uuid-1',
          status:       RideRequestStatus.REQUESTED,
          rideType:     RideType.SOLO,
          vehicleType:  VehicleType.AUTO,
        }),
      );
      expect(result.status).toBe(RideRequestStatus.REQUESTED);
    });

    it('defaults vehicleType to AUTO when not provided', async () => {
      const dto = makeDto({ vehicleType: undefined });
      const entity = makeEntity({ vehicleType: VehicleType.AUTO });
      repo.create.mockReturnValue(entity);
      repo.save.mockResolvedValue(entity);

      await service.createRequest('user-uuid-1', dto);

      expect(repo.create).toHaveBeenCalledWith(
        expect.objectContaining({ vehicleType: VehicleType.AUTO }),
      );
    });

    it('persists the entity by calling save', async () => {
      const entity = makeEntity();
      repo.create.mockReturnValue(entity);
      repo.save.mockResolvedValue(entity);

      await service.createRequest('user-uuid-1', makeDto());
      expect(repo.save).toHaveBeenCalledWith(entity);
    });

    it('propagates save errors', async () => {
      repo.create.mockReturnValue(makeEntity());
      repo.save.mockRejectedValue(new Error('DB connection error'));

      await expect(service.createRequest('user-uuid-1', makeDto())).rejects.toThrow('DB connection error');
    });
  });

  // ── getRequest ───────────────────────────────────────────────────────────

  describe('getRequest', () => {
    it('returns the ride request when found', async () => {
      repo.findOne.mockResolvedValue(makeEntity());
      const result = await service.getRequest('req-uuid-1');
      expect(result?.id).toBe('req-uuid-1');
      expect(repo.findOne).toHaveBeenCalledWith({ where: { id: 'req-uuid-1' } });
    });

    it('returns null when not found', async () => {
      repo.findOne.mockResolvedValue(null);
      const result = await service.getRequest('ghost-uuid');
      expect(result).toBeNull();
    });
  });

  // ── getActiveRequestForUser ──────────────────────────────────────────────

  describe('getActiveRequestForUser', () => {
    it('queries for REQUESTED status ordered by requestedAt DESC', async () => {
      const entity = makeEntity();
      repo.findOne.mockResolvedValue(entity);

      const result = await service.getActiveRequestForUser('user-uuid-1');

      expect(repo.findOne).toHaveBeenCalledWith({
        where: { riderUserId: 'user-uuid-1', status: RideRequestStatus.REQUESTED },
        order: { requestedAt: 'DESC' },
      });
      expect(result?.riderUserId).toBe('user-uuid-1');
    });

    it('returns null when user has no active request', async () => {
      repo.findOne.mockResolvedValue(null);
      const result = await service.getActiveRequestForUser('user-uuid-1');
      expect(result).toBeNull();
    });
  });

  // ── cancelRequest ────────────────────────────────────────────────────────

  describe('cancelRequest', () => {
    it('updates status to CANCELLED for the matching id and userId', async () => {
      repo.update.mockResolvedValue({ affected: 1 } as any);

      await service.cancelRequest('req-uuid-1', 'user-uuid-1');

      expect(repo.update).toHaveBeenCalledWith(
        { id: 'req-uuid-1', riderUserId: 'user-uuid-1' },
        { status: RideRequestStatus.CANCELLED },
      );
    });

    it('does not throw even if no row is matched (wrong user)', async () => {
      repo.update.mockResolvedValue({ affected: 0 } as any);
      await expect(service.cancelRequest('req-uuid-1', 'wrong-user')).resolves.toBeUndefined();
    });
  });
});
