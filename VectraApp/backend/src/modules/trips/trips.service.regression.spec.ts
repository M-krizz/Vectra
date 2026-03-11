import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { TripsService } from './trips.service';
import { TripEntity, TripStatus } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { SocketGateway } from '../../realtime/socket.gateway';

// ── Helpers ────────────────────────────────────────────────────────────────

const makeTrip = (overrides: Partial<TripEntity> = {}): TripEntity =>
  ({
    id: 'trip-uuid-1',
    driverUserId: 'driver-uuid-1',
    status: TripStatus.IN_PROGRESS,
    assignedAt: new Date('2024-06-01T10:05:00Z'),
    startAt: new Date('2024-06-01T10:10:00Z'),
    endAt: null,
    currentRoutePolyline: null,
    createdAt: new Date('2024-06-01T10:00:00Z'),
    updatedAt: new Date('2024-06-01T10:10:00Z'),
    driver: null,
    tripRiders: [],
    events: [],
    ...overrides,
  } as TripEntity);

const makeRepo = () => ({
  findOne: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
});

const makeMockGateway = () => ({
  emitTripStatus: jest.fn(),
  emitLocationUpdate: jest.fn(),
});

// ═══════════════════════════════════════════════════════════════════════════

describe('TripsService – Regression (updateTripStatus + SocketGateway)', () => {
  let service: TripsService;
  let tripRepo: ReturnType<typeof makeRepo>;
  let eventRepo: ReturnType<typeof makeRepo>;
  let socketGateway: ReturnType<typeof makeMockGateway>;

  beforeEach(async () => {
    tripRepo = makeRepo();
    eventRepo = makeRepo();
    socketGateway = makeMockGateway();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TripsService,
        { provide: getRepositoryToken(TripEntity), useValue: tripRepo },
        { provide: getRepositoryToken(TripEventEntity), useValue: eventRepo },
        { provide: SocketGateway, useValue: socketGateway },
      ],
    }).compile();

    service = module.get<TripsService>(TripsService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── updateTripStatus ─────────────────────────────────────────────────────

  describe('updateTripStatus', () => {
    it('throws NotFoundException when trip does not exist', async () => {
      tripRepo.findOne.mockResolvedValue(null);
      await expect(
        service.updateTripStatus('ghost-uuid', TripStatus.COMPLETED),
      ).rejects.toThrow(NotFoundException);
    });

    it('updates status to IN_PROGRESS and sets startAt when not previously set', async () => {
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS, startAt: null as any });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue({ ...trip, status: TripStatus.IN_PROGRESS });

      await service.updateTripStatus('trip-uuid-1', TripStatus.IN_PROGRESS);

      const savedArg = tripRepo.save.mock.calls[0][0];
      expect(savedArg.startAt).toBeInstanceOf(Date);
    });

    it('does NOT overwrite startAt when already set', async () => {
      const existingStart = new Date('2024-06-01T10:10:00Z');
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS, startAt: existingStart });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue(trip);

      await service.updateTripStatus('trip-uuid-1', TripStatus.IN_PROGRESS);

      const savedArg = tripRepo.save.mock.calls[0][0];
      expect(savedArg.startAt).toEqual(existingStart);
    });

    it('sets endAt when status is COMPLETED and endAt is not set', async () => {
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS, endAt: null as any });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue(trip);

      await service.updateTripStatus('trip-uuid-1', TripStatus.COMPLETED);

      const savedArg = tripRepo.save.mock.calls[0][0];
      expect(savedArg.endAt).toBeInstanceOf(Date);
    });

    it('sets endAt when status is CANCELLED and endAt is not set', async () => {
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS, endAt: null as any });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue(trip);

      await service.updateTripStatus('trip-uuid-1', TripStatus.CANCELLED);

      const savedArg = tripRepo.save.mock.calls[0][0];
      expect(savedArg.endAt).toBeInstanceOf(Date);
    });

    it('does NOT overwrite endAt when already set', async () => {
      const existingEnd = new Date('2024-06-01T11:00:00Z');
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS, endAt: existingEnd });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue(trip);

      await service.updateTripStatus('trip-uuid-1', TripStatus.COMPLETED);

      const savedArg = tripRepo.save.mock.calls[0][0];
      expect(savedArg.endAt).toEqual(existingEnd);
    });

    it('calls socketGateway.emitTripStatus with the correct tripId and new status', async () => {
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue(trip);

      await service.updateTripStatus('trip-uuid-1', TripStatus.COMPLETED);

      expect(socketGateway.emitTripStatus).toHaveBeenCalledWith(
        'trip-uuid-1',
        TripStatus.COMPLETED,
      );
    });

    it('emits CANCELLED status via socketGateway', async () => {
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue(trip);

      await service.updateTripStatus('trip-uuid-1', TripStatus.CANCELLED);

      expect(socketGateway.emitTripStatus).toHaveBeenCalledWith(
        'trip-uuid-1',
        TripStatus.CANCELLED,
      );
    });

    it('returns the updated trip entity after save', async () => {
      const trip = makeTrip({ status: TripStatus.IN_PROGRESS });
      tripRepo.findOne.mockResolvedValue(trip);
      tripRepo.save.mockResolvedValue({ ...trip, status: TripStatus.COMPLETED });

      const result = await service.updateTripStatus('trip-uuid-1', TripStatus.COMPLETED);
      expect(result.status).toBe(TripStatus.COMPLETED);
    });

    it('does NOT call emitTripStatus when trip is not found (throws first)', async () => {
      tripRepo.findOne.mockResolvedValue(null);

      await expect(
        service.updateTripStatus('ghost', TripStatus.COMPLETED),
      ).rejects.toThrow(NotFoundException);

      expect(socketGateway.emitTripStatus).not.toHaveBeenCalled();
    });
  });

  // ── updateDriverLocation with SocketGateway ───────────────────────────────

  describe('updateDriverLocation (SocketGateway integration)', () => {
    it('calls socketGateway.emitLocationUpdate after saving the event', async () => {
      const evt = {
        id: 'evt-1',
        tripId: 'trip-uuid-1',
        eventType: 'DRIVER_LOCATION',
        metadata: { lat: 28.5, lng: 77.5 },
      };
      eventRepo.create.mockReturnValue(evt);
      eventRepo.save.mockResolvedValue(evt);

      await service.updateDriverLocation('trip-uuid-1', 28.5, 77.5);

      expect(socketGateway.emitLocationUpdate).toHaveBeenCalledWith(
        'trip-uuid-1',
        28.5,
        77.5,
      );
    });

    it('does NOT call emitLocationUpdate if save throws', async () => {
      eventRepo.create.mockReturnValue({});
      eventRepo.save.mockRejectedValue(new Error('DB error'));

      await expect(
        service.updateDriverLocation('trip-uuid-1', 0, 0),
      ).rejects.toThrow('DB error');

      expect(socketGateway.emitLocationUpdate).not.toHaveBeenCalled();
    });
  });
});
