import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, UnauthorizedException, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import * as request from 'supertest';
import { RideRequestsController } from '../src/modules/ride_requests/ride-requests.controller';
import { RideRequestsService } from '../src/modules/ride_requests/ride-requests.service';
import { SocketGateway } from '../src/realtime/socket.gateway';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

/**
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  E2E TEST: COMPLETE RIDE BOOKING JOURNEY                             │
 * │                                                                      │
 * │  Tests the complete lifecycle via HTTP — rider → driver → cancel.   │
 * │  Socket emission is validated at the service/unit layer separately.  │
 * └──────────────────────────────────────────────────────────────────────┘
 */

const MOCK_RIDER    = { userId: 'user-rider-001', role: 'RIDER' };
const MOCK_DRIVER_A = { userId: 'user-driver-001', role: 'DRIVER' };

const VALID_PICKUP = { type: 'Point', coordinates: [77.5946, 12.9716] };
const VALID_DROP   = { type: 'Point', coordinates: [77.6101, 12.9352] };

const MOCK_RIDE_REQUEST = {
  id: 'ride-e2e-001',
  riderUserId: 'user-rider-001',
  status: 'REQUESTED',
  vehicleType: 'AUTO',
  pickupPoint: VALID_PICKUP,
  dropPoint: VALID_DROP,
  requestedAt: new Date().toISOString(),
};

const ACCEPTED_RIDE  = { ...MOCK_RIDE_REQUEST, status: 'ACCEPTED', driverUserId: 'user-driver-001' };
const CANCELLED_RIDE = { ...MOCK_RIDE_REQUEST, status: 'CANCELLED' };

const makeMockRideService = () => ({
  createRequest:             jest.fn(),
  getRequest:                jest.fn(),
  acceptSoloRideRequest:     jest.fn(),
  cancelRequest:             jest.fn(),
  getActiveRequestForUser:   jest.fn(),
  getActiveRequestForDriver: jest.fn(),
});

const makeMockSocketGateway = () => ({
  emitTripStatus:     jest.fn(),
  emitLocationUpdate: jest.fn(),
});

const makeGuard = (mockUser: object) => ({
  canActivate: (ctx: any) => {
    const req = ctx.switchToHttp().getRequest();
    const auth = req.headers.authorization;
    if (!auth || !auth.startsWith('Bearer ')) throw new UnauthorizedException('Missing token');
    req.user = mockUser;
    return true;
  },
});

// ═══════════════════════════════════════════════════════════════════════════

describe('E2E Journey: Complete Ride Booking Lifecycle (Rider)', () => {
  let app: INestApplication;
  let rideService: ReturnType<typeof makeMockRideService>;
  let socketGateway: ReturnType<typeof makeMockSocketGateway>;

  beforeAll(async () => {
    rideService   = makeMockRideService();
    socketGateway = makeMockSocketGateway();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [RideRequestsController],
      providers: [
        { provide: RideRequestsService, useValue: rideService },
        { provide: SocketGateway,        useValue: socketGateway },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(makeGuard(MOCK_RIDER))
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  // ── STEP 1: Create ride ───────────────────────────────────────────────────

  it('E2E-RIDE-STEP-01 → Rider requests ride with valid payload → 201 REQUESTED', async () => {
    rideService.getActiveRequestForUser.mockResolvedValue(null);
    rideService.createRequest.mockResolvedValue(MOCK_RIDE_REQUEST);

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer rider-token')
      .send({
        pickupPoint: VALID_PICKUP,
        dropPoint:   VALID_DROP,
        rideType:    'SOLO',
        vehicleType: 'AUTO',
      })
      .expect(201);

    expect(res.body.status).toBe('REQUESTED');
    expect(res.body.id).toBe('ride-e2e-001');
    expect(rideService.createRequest).toHaveBeenCalledTimes(1);
  });

  it('E2E-RIDE-STEP-02 → Rider has active ride and tries to request again → 400 duplicate guard', async () => {
    rideService.getActiveRequestForUser.mockResolvedValue(MOCK_RIDE_REQUEST);
    rideService.createRequest.mockRejectedValue(
      new BadRequestException('User already has an active ride request'),
    );

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer rider-token')
      .send({
        pickupPoint: VALID_PICKUP,
        dropPoint:   VALID_DROP,
        rideType:    'SOLO',
      })
      .expect(400);

    expect(res.body.message).toContain('active ride request');
  });

  it('E2E-RIDE-STEP-03 → Unauthenticated request → 401, no ride created', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .send({ pickupPoint: VALID_PICKUP, dropPoint: VALID_DROP, rideType: 'SOLO' })
      .expect(401);

    expect(rideService.createRequest).not.toHaveBeenCalled();
  });

  it('E2E-RIDE-STEP-04 → Empty body (missing pickupPoint, dropPoint, rideType) → 400 validation', async () => {
    rideService.getActiveRequestForUser.mockResolvedValue(null);

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer rider-token')
      .send({})
      .expect(400);

    expect(res.body.message).toBeInstanceOf(Array);
    expect(rideService.createRequest).not.toHaveBeenCalled();
  });

  it('E2E-RIDE-STEP-05 → Invalid rideType enum value → 400 validation', async () => {
    rideService.getActiveRequestForUser.mockResolvedValue(null);

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer rider-token')
      .send({
        pickupPoint: VALID_PICKUP,
        dropPoint:   VALID_DROP,
        rideType:    'FLYING_CAR', // invalid enum
      })
      .expect(400);

    expect(res.body.message).toBeInstanceOf(Array);
  });

  // ── STEP 2: Cancel ride ───────────────────────────────────────────────────

  it('E2E-RIDE-STEP-06 → Rider cancels active ride → 200 CANCELLED', async () => {
    rideService.cancelRequest.mockResolvedValue(CANCELLED_RIDE);

    const res = await request(app.getHttpServer())
      .patch('/api/v1/ride-requests/ride-e2e-001/cancel')
      .set('Authorization', 'Bearer rider-token')
      .expect(200);

    expect(res.body.status).toBe('CANCELLED');
    expect(rideService.cancelRequest).toHaveBeenCalledWith(
      'ride-e2e-001', 'user-rider-001',
    );
  });

  it('E2E-RIDE-STEP-07 → Cancel again (idempotent) → 200 CANCELLED still returned', async () => {
    rideService.cancelRequest.mockResolvedValue(CANCELLED_RIDE);

    const res = await request(app.getHttpServer())
      .patch('/api/v1/ride-requests/ride-e2e-001/cancel')
      .set('Authorization', 'Bearer rider-token')
      .expect(200);

    expect(res.body.status).toBe('CANCELLED');
  });

  it('E2E-RIDE-STEP-08 → Cancel without auth → 401', async () => {
    await request(app.getHttpServer())
      .patch('/api/v1/ride-requests/ride-e2e-001/cancel')
      .expect(401);

    expect(rideService.cancelRequest).not.toHaveBeenCalled();
  });
});

// ═══════════════════════════════════════════════════════════════════════════

describe('E2E Journey: Complete Ride Booking Lifecycle (Driver)', () => {
  let app: INestApplication;
  let rideService: ReturnType<typeof makeMockRideService>;
  let socketGateway: ReturnType<typeof makeMockSocketGateway>;

  beforeAll(async () => {
    rideService   = makeMockRideService();
    socketGateway = makeMockSocketGateway();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [RideRequestsController],
      providers: [
        { provide: RideRequestsService, useValue: rideService },
        { provide: SocketGateway,        useValue: socketGateway },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(makeGuard(MOCK_DRIVER_A))
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });

  afterAll(async () => await app.close());
  afterEach(() => jest.clearAllMocks());

  it('E2E-DRIVER-STEP-01 → Driver accepts pending ride → 201 ACCEPTED', async () => {
    rideService.acceptSoloRideRequest.mockResolvedValue(ACCEPTED_RIDE);

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests/ride-e2e-001/accept')
      .set('Authorization', 'Bearer driver-a-token')
      .expect(201);

    expect(res.body.status).toBe('ACCEPTED');
    expect(res.body.driverUserId).toBe('user-driver-001');
    expect(rideService.acceptSoloRideRequest).toHaveBeenCalledWith(
      'ride-e2e-001', 'user-driver-001',
    );
  });

  it('E2E-DRIVER-STEP-02 → Driver B accepts same ride → 409 race condition lock', async () => {
    rideService.acceptSoloRideRequest.mockRejectedValue(
      new ConflictException('Ride request is no longer available'),
    );

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests/ride-e2e-001/accept')
      .set('Authorization', 'Bearer driver-b-token')
      .expect(409);

    expect(res.body.message).toContain('no longer available');
  });

  it('E2E-DRIVER-STEP-03 → Accept non-existent ride → 404 Not Found', async () => {
    rideService.acceptSoloRideRequest.mockRejectedValue(
      new NotFoundException('Ride request not found'),
    );

    await request(app.getHttpServer())
      .post('/api/v1/ride-requests/ghost-id/accept')
      .set('Authorization', 'Bearer driver-a-token')
      .expect(404);
  });

  it('E2E-DRIVER-STEP-04 → Accept without auth → 401', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/ride-requests/ride-e2e-001/accept')
      .expect(401);

    expect(rideService.acceptSoloRideRequest).not.toHaveBeenCalled();
  });
});
