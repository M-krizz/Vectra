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
    id:                   'trip-uuid-1',
    driverUserId:         'driver-uuid-1',
    status:               TripStatus.IN_PROGRESS,
    assignedAt:           new Date('2024-06-01T10:05:00Z'),
    startAt:              new Date('2024-06-01T10:10:00Z'),
    endAt:                null,
    currentRoutePolyline: null,
    createdAt:            new Date('2024-06-01T10:00:00Z'),
    updatedAt:            new Date('2024-06-01T10:10:00Z'),
    driver:               null,
    tripRiders:           [],
    events:               [],
    ...overrides,
  } as TripEntity);

const makeEvent = (overrides: Partial<TripEventEntity> = {}): TripEventEntity =>
  ({
    id:        'evt-uuid-1',
    tripId:    'trip-uuid-1',
    eventType: 'DRIVER_LOCATION',
    oldValue:  null,
    newValue:  null,
    metadata:  { lat: 11.0168, lng: 76.9558 },
    createdAt: new Date(),
    trip:      null as any,
    ...overrides,
  } as TripEventEntity);

const makeRepo = () => ({
  findOne: jest.fn(),
  create:  jest.fn(),
  save:    jest.fn(),
});

// ── Tests ──────────────────────────────────────────────────────────────────

describe('TripsService', () => {
  let service: TripsService;
  let tripRepo: ReturnType<typeof makeRepo>;
  let eventRepo: ReturnType<typeof makeRepo>;

  beforeEach(async () => {
    tripRepo  = makeRepo();
    eventRepo = makeRepo();

    const mockSocketGateway = { emitTripStatus: jest.fn(), emitLocationUpdate: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TripsService,
        { provide: getRepositoryToken(TripEntity),      useValue: tripRepo  },
        { provide: getRepositoryToken(TripEventEntity), useValue: eventRepo },
        { provide: SocketGateway, useValue: mockSocketGateway },
      ],
    }).compile();

    service = module.get<TripsService>(TripsService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── getTrip ──────────────────────────────────────────────────────────────

  describe('getTrip', () => {
    it('returns the trip with latestLocation when found', async () => {
      tripRepo.findOne.mockResolvedValue(makeTrip());
      const event = makeEvent({ metadata: { lat: 11.0168, lng: 76.9558 } });
      eventRepo.findOne.mockResolvedValue(event);

      const result = await service.getTrip('trip-uuid-1');

      expect(result.id).toBe('trip-uuid-1');
      expect(result.latestLocation).toEqual({ lat: 11.0168, lng: 76.9558 });
    });

    it('returns latestLocation as null when no DRIVER_LOCATION event exists', async () => {
      tripRepo.findOne.mockResolvedValue(makeTrip());
      eventRepo.findOne.mockResolvedValue(null);

      const result = await service.getTrip('trip-uuid-1');
      expect(result.latestLocation).toBeNull();
    });

    it('queries trip with driver, tripRiders, and rider relations', async () => {
      tripRepo.findOne.mockResolvedValue(makeTrip());
      eventRepo.findOne.mockResolvedValue(null);

      await service.getTrip('trip-uuid-1');

      expect(tripRepo.findOne).toHaveBeenCalledWith({
        where:     { id: 'trip-uuid-1' },
        relations: ['driver', 'tripRiders', 'tripRiders.rider'],
      });
    });

    it('queries the latest DRIVER_LOCATION event sorted by createdAt DESC', async () => {
      tripRepo.findOne.mockResolvedValue(makeTrip());
      eventRepo.findOne.mockResolvedValue(null);

      await service.getTrip('trip-uuid-1');

      expect(eventRepo.findOne).toHaveBeenCalledWith({
        where: { tripId: 'trip-uuid-1', eventType: 'DRIVER_LOCATION' },
        order: { createdAt: 'DESC' },
      });
    });

    it('throws NotFoundException when trip is not found', async () => {
      tripRepo.findOne.mockResolvedValue(null);
      await expect(service.getTrip('ghost-uuid')).rejects.toThrow(NotFoundException);
    });
  });

  // ── updateDriverLocation ─────────────────────────────────────────────────

  describe('updateDriverLocation', () => {
    it('creates and saves a DRIVER_LOCATION event with correct metadata', async () => {
      const event = makeEvent();
      eventRepo.create.mockReturnValue(event);
      eventRepo.save.mockResolvedValue(event);

      await service.updateDriverLocation('trip-uuid-1', 11.0168, 76.9558);

      expect(eventRepo.create).toHaveBeenCalledWith({
        tripId:    'trip-uuid-1',
        eventType: 'DRIVER_LOCATION',
        metadata:  { lat: 11.0168, lng: 76.9558 },
      });
      expect(eventRepo.save).toHaveBeenCalledWith(event);
    });

    it('saves different coordinates correctly', async () => {
      const event = makeEvent({ metadata: { lat: 11.025, lng: 77.001 } });
      eventRepo.create.mockReturnValue(event);
      eventRepo.save.mockResolvedValue(event);

      await service.updateDriverLocation('trip-uuid-1', 11.025, 77.001);

      expect(eventRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ metadata: { lat: 11.025, lng: 77.001 } }),
      );
    });

    it('propagates save errors to the caller', async () => {
      eventRepo.create.mockReturnValue(makeEvent());
      eventRepo.save.mockRejectedValue(new Error('DB write failure'));

      await expect(
        service.updateDriverLocation('trip-uuid-1', 11.0168, 76.9558),
      ).rejects.toThrow('DB write failure');
    });
  });
});
