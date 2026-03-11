import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, NotFoundException } from '@nestjs/common';
import * as request from 'supertest';
import { getRepositoryToken } from '@nestjs/typeorm';
import { TripsController } from '../src/modules/trips/trips.controller';
import { TripsService } from '../src/modules/trips/trips.service';
import { RealtimeModule } from '../src/realtime/realtime.module';
import { TripEntity, TripStatus } from '../src/modules/trips/trip.entity';
import { TripEventEntity } from '../src/modules/trips/trip-event.entity';
import { SocketGateway } from '../src/realtime/socket.gateway';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

/**
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  INTEGRATION TESTS: FULL TRIP LIFECYCLE                              │
 * │                                                                      │
 * │  ① During trip  — location pings, DB save + socket                   │
 * │  ② End of trip  — /start, /complete, /cancel + socket                │
 * │  ③ Post trip    — rider fetches completed/cancelled trip             │
 * └──────────────────────────────────────────────────────────────────────┘
 */

// ── Trip state constants ──────────────────────────────────────────────────

const ASSIGNED_TRIP = {
  id: 'trip-123',
  status: TripStatus.ASSIGNED,
  startAt: null,
  endAt: null,
};

const IN_PROGRESS_TRIP = {
  id: 'trip-123',
  status: TripStatus.IN_PROGRESS,
  startAt: new Date('2026-03-11T00:00:00Z'),
  endAt: null,
};

const COMPLETED_TRIP = {
  id: 'trip-123',
  status: TripStatus.COMPLETED,
  startAt: new Date('2026-03-11T00:00:00Z'),
  endAt: new Date('2026-03-11T00:30:00Z'),
};

const CANCELLED_TRIP = {
  id: 'trip-123',
  status: TripStatus.CANCELLED,
  startAt: new Date('2026-03-11T00:00:00Z'),
  endAt: new Date('2026-03-11T00:10:00Z'),
};

// ── Helpers ───────────────────────────────────────────────────────────────

const makeDriverGuard = () => ({
  canActivate: (ctx: any) => {
    ctx.switchToHttp().getRequest().user = { userId: 'test-driver-id', role: 'DRIVER' };
    return true;
  },
});

const makeRiderGuard = () => ({
  canActivate: (ctx: any) => {
    ctx.switchToHttp().getRequest().user = { userId: 'test-rider-id', role: 'RIDER' };
    return true;
  },
});

async function buildApp(
  tripRepoMock: object,
  eventRepoMock: object,
  guard: object,
): Promise<{ app: INestApplication; socketGateway: SocketGateway }> {
  const mod = await Test.createTestingModule({
    imports: [RealtimeModule],
    controllers: [TripsController],
    providers: [
      TripsService,
      { provide: getRepositoryToken(TripEntity),      useValue: tripRepoMock },
      { provide: getRepositoryToken(TripEventEntity), useValue: eventRepoMock },
    ],
  })
    .overrideGuard(JwtAuthGuard)
    .useValue(guard)
    .compile();

  const app = mod.createNestApplication();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
  await app.init();
  return { app, socketGateway: mod.get<SocketGateway>(SocketGateway) };
}

// ═══════════════════════════════════════════════════════════════════════════
// ① DURING TRIP — Location Updates
// ═══════════════════════════════════════════════════════════════════════════

describe('Integration: During-Trip Location Updates', () => {
  let app: INestApplication;
  let socketGateway: SocketGateway;
  let mockEventRepo: { create: jest.Mock; save: jest.Mock; findOne: jest.Mock };

  beforeAll(async () => {
    const mockTripRepo = { findOne: jest.fn().mockResolvedValue({ id: 'trip-123' }), save: jest.fn() };
    mockEventRepo = {
      create: jest.fn().mockImplementation((dto) => ({ id: 'evt-1', ...dto })),
      save:   jest.fn().mockImplementation((e) => Promise.resolve(e)),
      findOne: jest.fn(),
    };
    ({ app, socketGateway } = await buildApp(mockTripRepo, mockEventRepo, makeDriverGuard()));
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('INT-DUR-001 → First location ping: event saved to DB + emitLocationUpdate socket called', async () => {
    jest.spyOn(socketGateway, 'emitLocationUpdate');

    await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/location')
      .send({ lat: 12.9716, lng: 77.5946 })
      .expect(200);

    expect(mockEventRepo.save).toHaveBeenCalledTimes(1);
    expect(socketGateway.emitLocationUpdate).toHaveBeenCalledWith('trip-123', 12.9716, 77.5946);
  });

  it('INT-DUR-002 → Second location ping (approaching pickup): new coords saved + socket emitted', async () => {
    jest.spyOn(socketGateway, 'emitLocationUpdate');

    await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/location')
      .send({ lat: 12.9740, lng: 77.5960 })
      .expect(200);

    expect(mockEventRepo.save).toHaveBeenCalledTimes(1);
    expect(socketGateway.emitLocationUpdate).toHaveBeenCalledWith('trip-123', 12.9740, 77.5960);
  });

  it('INT-DUR-003 → 5 consecutive pings (every 5s): all 5 DB saves + 5 sockets emitted', async () => {
    jest.spyOn(socketGateway, 'emitLocationUpdate');

    const coords = [
      { lat: 12.9730, lng: 77.5970 },
      { lat: 12.9720, lng: 77.5990 },
      { lat: 12.9710, lng: 77.6010 },
      { lat: 12.9700, lng: 77.6030 },
      { lat: 12.9690, lng: 77.6050 },
    ];

    for (const c of coords) {
      await request(app.getHttpServer())
        .patch('/api/v1/trips/trip-123/location')
        .send(c)
        .expect(200);
    }

    expect(mockEventRepo.save).toHaveBeenCalledTimes(5);
    expect(socketGateway.emitLocationUpdate).toHaveBeenCalledTimes(5);
    expect(socketGateway.emitLocationUpdate).toHaveBeenLastCalledWith('trip-123', 12.9690, 77.6050);
  });

  it('INT-DUR-004 → DB save failure: socket emit is NOT called (no partial state)', async () => {
    jest.spyOn(socketGateway, 'emitLocationUpdate');
    mockEventRepo.save.mockRejectedValueOnce(new Error('DB write error'));

    await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/location')
      .send({ lat: 12.9716, lng: 77.5946 })
      .expect(500);

    expect(socketGateway.emitLocationUpdate).not.toHaveBeenCalled();
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// ② TRIP STATUS TRANSITIONS — /start, /complete, /cancel
// ═══════════════════════════════════════════════════════════════════════════

describe('Integration: Trip Status Transitions (start → complete → cancel)', () => {
  let app: INestApplication;
  let socketGateway: SocketGateway;
  let mockTripRepo: { findOne: jest.Mock; save: jest.Mock };

  beforeAll(async () => {
    mockTripRepo = {
      findOne: jest.fn(),
      save:    jest.fn().mockImplementation((e) => Promise.resolve(e)),
    };
    const mockEventRepo = {
      create: jest.fn(), save: jest.fn(), findOne: jest.fn(),
    };
    ({ app, socketGateway } = await buildApp(mockTripRepo, mockEventRepo, makeDriverGuard()));
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('INT-STAT-001 → PATCH /start: status → IN_PROGRESS, startAt set, emitTripStatus(id, IN_PROGRESS)', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');
    // Return a mutable copy
    mockTripRepo.findOne.mockResolvedValueOnce({ ...ASSIGNED_TRIP });

    const res = await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/start')
      .expect(200);

    expect(res.body.status).toBe(TripStatus.IN_PROGRESS);
    expect(res.body.startAt).toBeTruthy();
    // Service calls emitTripStatus with exactly 2 args (id, status)
    expect(socketGateway.emitTripStatus).toHaveBeenCalledWith('trip-123', TripStatus.IN_PROGRESS);
  });

  it('INT-STAT-002 → PATCH /complete: status → COMPLETED, endAt set, emitTripStatus(id, COMPLETED)', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');
    mockTripRepo.findOne.mockResolvedValueOnce({ ...IN_PROGRESS_TRIP });

    const res = await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/complete')
      .expect(200);

    expect(res.body.status).toBe(TripStatus.COMPLETED);
    expect(res.body.endAt).toBeTruthy();
    expect(socketGateway.emitTripStatus).toHaveBeenCalledWith('trip-123', TripStatus.COMPLETED);
  });

  it('INT-STAT-003 → PATCH /cancel: status → CANCELLED, endAt set, emitTripStatus(id, CANCELLED)', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');
    mockTripRepo.findOne.mockResolvedValueOnce({ ...IN_PROGRESS_TRIP });

    const res = await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/cancel')
      .expect(200);

    expect(res.body.status).toBe(TripStatus.CANCELLED);
    expect(res.body.endAt).toBeTruthy();
    expect(socketGateway.emitTripStatus).toHaveBeenCalledWith('trip-123', TripStatus.CANCELLED);
  });

  it('INT-STAT-004 → Start non-existent trip → 404, emitTripStatus NOT called', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');
    mockTripRepo.findOne.mockResolvedValueOnce(null);

    await request(app.getHttpServer())
      .patch('/api/v1/trips/ghost-trip/start')
      .expect(404);

    expect(socketGateway.emitTripStatus).not.toHaveBeenCalled();
  });

  it('INT-STAT-005 → Complete non-existent trip → 404, emitTripStatus NOT called', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');
    mockTripRepo.findOne.mockResolvedValueOnce(null);

    await request(app.getHttpServer())
      .patch('/api/v1/trips/ghost-trip/complete')
      .expect(404);

    expect(socketGateway.emitTripStatus).not.toHaveBeenCalled();
  });

  it('INT-STAT-006 → DB save failure on status update → 500, emitTripStatus NOT called', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');
    mockTripRepo.findOne.mockResolvedValueOnce({ ...IN_PROGRESS_TRIP });
    mockTripRepo.save.mockRejectedValueOnce(new Error('DB write failed'));

    await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/complete')
      .expect(500);

    expect(socketGateway.emitTripStatus).not.toHaveBeenCalled();
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// ③ POST-TRIP — Rider fetches trip data after completion/cancellation
// ═══════════════════════════════════════════════════════════════════════════

describe('Integration: Post-Trip — Rider Fetches Completed/Cancelled Trip', () => {
  let app: INestApplication;
  let mockTripRepo: { findOne: jest.Mock; save: jest.Mock };
  let mockEventRepo: { create: jest.Mock; save: jest.Mock; findOne: jest.Mock };

  beforeAll(async () => {
    mockTripRepo = {
      findOne: jest.fn(),
      save:    jest.fn(),
    };
    mockEventRepo = {
      create:  jest.fn(),
      save:    jest.fn(),
      // getTrip calls eventRepo.findOne for latest DRIVER_LOCATION
      findOne: jest.fn().mockResolvedValue({
        metadata: { lat: 12.9710, lng: 77.6020 },
      }),
    };
    ({ app } = await buildApp(mockTripRepo, mockEventRepo, makeRiderGuard()));
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('INT-POST-001 → Rider fetches active trip: returns IN_PROGRESS + latestLocation + driver info', async () => {
    mockTripRepo.findOne.mockResolvedValueOnce({
      ...IN_PROGRESS_TRIP,
      driver: { id: 'driver-id', fullName: 'Test Driver' },
      tripRiders: [],
    });

    const res = await request(app.getHttpServer())
      .get('/api/v1/trips/trip-123')
      .expect(200);

    expect(res.body.id).toBe('trip-123');
    expect(res.body.status).toBe(TripStatus.IN_PROGRESS);
    expect(res.body.latestLocation).toMatchObject({ lat: 12.9710, lng: 77.6020 });
  });

  it('INT-POST-002 → Rider fetches completed trip: status COMPLETED, endAt is set', async () => {
    mockTripRepo.findOne.mockResolvedValueOnce({
      ...COMPLETED_TRIP,
      driver: null,
      tripRiders: [],
    });

    const res = await request(app.getHttpServer())
      .get('/api/v1/trips/trip-123')
      .expect(200);

    expect(res.body.status).toBe(TripStatus.COMPLETED);
    expect(res.body.endAt).toBeTruthy();
  });

  it('INT-POST-003 → Rider fetches cancelled trip: status CANCELLED, endAt is set', async () => {
    mockTripRepo.findOne.mockResolvedValueOnce({
      ...CANCELLED_TRIP,
      driver: null,
      tripRiders: [],
    });

    const res = await request(app.getHttpServer())
      .get('/api/v1/trips/trip-123')
      .expect(200);

    expect(res.body.status).toBe(TripStatus.CANCELLED);
    expect(res.body.endAt).toBeTruthy();
  });

  it('INT-POST-004 → Fetch non-existent trip → 404 NotFoundException', async () => {
    mockTripRepo.findOne.mockResolvedValueOnce(null);

    await request(app.getHttpServer())
      .get('/api/v1/trips/no-such-trip')
      .expect(404);
  });
});
