import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, UnauthorizedException, NotFoundException } from '@nestjs/common';
import * as request from 'supertest';
import { TripsController } from '../src/modules/trips/trips.controller';
import { TripsService } from '../src/modules/trips/trips.service';
import { SocketGateway } from '../src/realtime/socket.gateway';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

/**
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  E2E TEST: COMPLETE TRIP LIFECYCLE                                   │
 * │                                                                      │
 * │  Routes:                                                             │
 * │    GET    /api/v1/trips/:id            → getTrip                     │
 * │    PATCH  /api/v1/trips/:id/location   → updateDriverLocation        │
 * │    PATCH  /api/v1/trips/:id/start      → updateTripStatus(IN_PROGRESS)│
 * │    PATCH  /api/v1/trips/:id/complete   → updateTripStatus(COMPLETED) │
 * │    PATCH  /api/v1/trips/:id/cancel     → updateTripStatus(CANCELLED) │
 * │                                                                      │
 * │  Socket assertions are validated at the service unit layer.          │
 * └──────────────────────────────────────────────────────────────────────┘
 */

const MOCK_DRIVER = { userId: 'user-driver-001', role: 'DRIVER' };
const MOCK_RIDER  = { userId: 'user-rider-001',  role: 'RIDER'  };
const TRIP_ID     = 'trip-e2e-001';

const makeMockTripsService = () => ({
  getTrip:              jest.fn(),
  updateDriverLocation: jest.fn(),
  updateTripStatus:     jest.fn(),
});

const makeMockSocketGateway = () => ({
  emitTripStatus:     jest.fn(),
  emitLocationUpdate: jest.fn(),
});

const makeGuard = (user: object) => ({
  canActivate: (ctx: any) => {
    const req = ctx.switchToHttp().getRequest();
    const auth = req.headers.authorization;
    if (!auth || !auth.startsWith('Bearer ')) throw new UnauthorizedException('Missing token');
    req.user = user;
    return true;
  },
});

async function buildApp(
  tripsService: ReturnType<typeof makeMockTripsService>,
  socketGateway: ReturnType<typeof makeMockSocketGateway>,
  user: object,
): Promise<INestApplication> {
  const moduleFixture: TestingModule = await Test.createTestingModule({
    controllers: [TripsController],
    providers: [
      { provide: TripsService,  useValue: tripsService  },
      { provide: SocketGateway, useValue: socketGateway },
    ],
  })
    .overrideGuard(JwtAuthGuard)
    .useValue(makeGuard(user))
    .compile();

  const app = moduleFixture.createNestApplication();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
  await app.init();
  return app;
}

// ═══════════════════════════════════════════════════════════════════════════

describe('E2E Journey: Driver Location Updates During Trip', () => {
  let app: INestApplication;
  let tripsService: ReturnType<typeof makeMockTripsService>;
  let socketGateway: ReturnType<typeof makeMockSocketGateway>;

  beforeAll(async () => {
    tripsService  = makeMockTripsService();
    socketGateway = makeMockSocketGateway();
    app = await buildApp(tripsService, socketGateway, MOCK_DRIVER);
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('E2E-TRIP-STEP-01 → Driver sends first location ping → 200 OK, service called with correct args', async () => {
    tripsService.updateDriverLocation.mockResolvedValue({ success: true });

    await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/location`)
      .set('Authorization', 'Bearer driver-token')
      .send({ lat: 12.9716, lng: 77.5946 })
      .expect(200);

    expect(tripsService.updateDriverLocation).toHaveBeenCalledWith(
      TRIP_ID, 12.9716, 77.5946,
    );
  });

  it('E2E-TRIP-STEP-02 → Driver sends second location (approaching pickup) → 200 OK updated coords', async () => {
    tripsService.updateDriverLocation.mockResolvedValue({ success: true });

    await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/location`)
      .set('Authorization', 'Bearer driver-token')
      .send({ lat: 12.9740, lng: 77.5960 })
      .expect(200);

    expect(tripsService.updateDriverLocation).toHaveBeenCalledWith(
      TRIP_ID, 12.9740, 77.5960,
    );
  });

  it('E2E-TRIP-STEP-03 → 3 consecutive location pings during trip → all 3 return 200', async () => {
    tripsService.updateDriverLocation.mockResolvedValue({ success: true });

    const coords = [
      { lat: 12.9730, lng: 77.5980 },
      { lat: 12.9710, lng: 77.6020 },
      { lat: 12.9680, lng: 77.6060 },
    ];

    for (const c of coords) {
      await request(app.getHttpServer())
        .patch(`/api/v1/trips/${TRIP_ID}/location`)
        .set('Authorization', 'Bearer driver-token')
        .send(c)
        .expect(200);
    }

    expect(tripsService.updateDriverLocation).toHaveBeenCalledTimes(3);
  });

  it('E2E-TRIP-STEP-04 → Location update for non-existent trip → 404 Not Found', async () => {
    tripsService.updateDriverLocation.mockRejectedValue(
      new NotFoundException('Trip not found'),
    );

    await request(app.getHttpServer())
      .patch('/api/v1/trips/ghost-trip/location')
      .set('Authorization', 'Bearer driver-token')
      .send({ lat: 12.9716, lng: 77.5946 })
      .expect(404);
  });

  it('E2E-TRIP-STEP-05 → Location update without auth → 401, service never called', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/location`)
      .send({ lat: 12.9716, lng: 77.5946 })
      .expect(401);

    expect(tripsService.updateDriverLocation).not.toHaveBeenCalled();
  });
});

// ═══════════════════════════════════════════════════════════════════════════

describe('E2E Journey: Trip Status Transitions (Driver → /start → /complete → /cancel)', () => {
  let app: INestApplication;
  let tripsService: ReturnType<typeof makeMockTripsService>;
  let socketGateway: ReturnType<typeof makeMockSocketGateway>;

  beforeAll(async () => {
    tripsService  = makeMockTripsService();
    socketGateway = makeMockSocketGateway();
    app = await buildApp(tripsService, socketGateway, MOCK_DRIVER);
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('E2E-TRIP-STEP-06 → PATCH /start → returns IN_PROGRESS with startAt timestamp', async () => {
    const startAt = new Date().toISOString();
    tripsService.updateTripStatus.mockResolvedValue({
      id: TRIP_ID, status: 'IN_PROGRESS', startAt, endAt: null,
    });

    const res = await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/start`)
      .set('Authorization', 'Bearer driver-token')
      .expect(200);

    expect(res.body.status).toBe('IN_PROGRESS');
    expect(res.body.startAt).toBeTruthy();
  });

  it('E2E-TRIP-STEP-07 → PATCH /complete → returns COMPLETED with endAt timestamp', async () => {
    const endAt = new Date().toISOString();
    tripsService.updateTripStatus.mockResolvedValue({
      id: TRIP_ID, status: 'COMPLETED', startAt: '2026-03-11T00:00:00Z', endAt,
    });

    const res = await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/complete`)
      .set('Authorization', 'Bearer driver-token')
      .expect(200);

    expect(res.body.status).toBe('COMPLETED');
    expect(res.body.endAt).toBeTruthy();
  });

  it('E2E-TRIP-STEP-08 → PATCH /cancel → returns CANCELLED with endAt timestamp', async () => {
    const endAt = new Date().toISOString();
    tripsService.updateTripStatus.mockResolvedValue({
      id: TRIP_ID, status: 'CANCELLED', startAt: '2026-03-11T00:00:00Z', endAt,
    });

    const res = await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/cancel`)
      .set('Authorization', 'Bearer driver-token')
      .expect(200);

    expect(res.body.status).toBe('CANCELLED');
    expect(res.body.endAt).toBeTruthy();
  });

  it('E2E-TRIP-STEP-09 → Start non-existent trip → 404 Not Found', async () => {
    tripsService.updateTripStatus.mockRejectedValue(new NotFoundException('Trip not found'));

    await request(app.getHttpServer())
      .patch('/api/v1/trips/ghost-trip/start')
      .set('Authorization', 'Bearer driver-token')
      .expect(404);
  });

  it('E2E-TRIP-STEP-10 → Complete without auth → 401, service never called', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/trips/${TRIP_ID}/complete`)
      .expect(401);

    expect(tripsService.updateTripStatus).not.toHaveBeenCalled();
  });
});

// ═══════════════════════════════════════════════════════════════════════════

describe('E2E Journey: Rider Views Trip Details', () => {
  let app: INestApplication;
  let tripsService: ReturnType<typeof makeMockTripsService>;
  let socketGateway: ReturnType<typeof makeMockSocketGateway>;

  beforeAll(async () => {
    tripsService  = makeMockTripsService();
    socketGateway = makeMockSocketGateway();
    app = await buildApp(tripsService, socketGateway, MOCK_RIDER);
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('E2E-TRIP-STEP-11 → GET /trips/:id → returns trip with latestLocation + driver info', async () => {
    tripsService.getTrip.mockResolvedValue({
      id: TRIP_ID,
      status: 'IN_PROGRESS',
      latestLocation: { lat: 12.9710, lng: 77.6020 },
      driver: { id: 'user-driver-001', fullName: 'Driver A' },
    });

    const res = await request(app.getHttpServer())
      .get(`/api/v1/trips/${TRIP_ID}`)
      .set('Authorization', 'Bearer rider-token')
      .expect(200);

    expect(res.body.id).toBe(TRIP_ID);
    expect(res.body.latestLocation).toMatchObject({ lat: 12.9710, lng: 77.6020 });
    expect(res.body.driver.fullName).toBe('Driver A');
  });

  it('E2E-TRIP-STEP-12 → GET non-existent trip → 404 Not Found', async () => {
    tripsService.getTrip.mockRejectedValue(new NotFoundException('Trip not found'));

    await request(app.getHttpServer())
      .get('/api/v1/trips/no-such-trip')
      .set('Authorization', 'Bearer rider-token')
      .expect(404);
  });

  it('E2E-TRIP-STEP-13 → GET trip without auth → 401', async () => {
    await request(app.getHttpServer())
      .get(`/api/v1/trips/${TRIP_ID}`)
      .expect(401);
  });
});
