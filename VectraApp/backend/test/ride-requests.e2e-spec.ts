import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, UnauthorizedException } from '@nestjs/common';
import * as request from 'supertest';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { RideRequestsController } from '../src/modules/ride_requests/ride-requests.controller';
import { RideRequestsService } from '../src/modules/ride_requests/ride-requests.service';
import { RealtimeModule } from '../src/realtime/realtime.module';
import { RideRequestEntity } from '../src/modules/ride_requests/ride-request.entity';
import { SocketGateway } from '../src/realtime/socket.gateway';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

describe('RideRequestsController (e2e)', () => {
  let app: INestApplication;
  let socketGateway: SocketGateway;

  beforeAll(async () => {
    // Mock guards to simulate authenticated user
    const mockAuthGuard = {
      canActivate: (context: any) => {
        const req = context.switchToHttp().getRequest();
        const authHeader = req.headers.authorization;
        if (!authHeader || authHeader !== 'Bearer valid-token') {
          throw new UnauthorizedException();
        }
        req.user = { userId: 'test-user-id', role: 'rider' };
        return true;
      },
    };

    const mockRepo = {
      create: jest.fn().mockImplementation((dto) => ({ id: 'mock-uuid-123', ...dto, status: 'REQUESTED' })),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
      findOne: jest.fn().mockResolvedValue(null),
      update: jest.fn().mockResolvedValue({ affected: 1 }),
    };

    const mockDataSource = {
      createQueryRunner: jest.fn().mockReturnValue({
        connect: jest.fn(),
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
        manager: {
          createQueryBuilder: jest.fn(),
          findOne: jest.fn(),
          create: jest.fn(),
          save: jest.fn(),
        },
      }),
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [RealtimeModule],
      controllers: [RideRequestsController],
      providers: [
        RideRequestsService,
        {
          provide: getRepositoryToken(RideRequestEntity),
          useValue: mockRepo,
        },
        {
          provide: DataSource,
          useValue: mockDataSource,
        },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(mockAuthGuard)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    
    socketGateway = moduleFixture.get<SocketGateway>(SocketGateway);
    
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('/api/v1/ride-requests (POST) - creates request & emits socket', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');

    const payload = {
      pickupPoint: { type: 'Point', coordinates: [77.1, 28.1] },
      dropPoint: { type: 'Point', coordinates: [77.2, 28.2] },
      pickupAddress: 'Start Location',
      dropAddress: 'End Location',
      rideType: 'SOLO',
      vehicleType: 'AUTO',
    };

    const response = await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer valid-token')
      .send(payload)
      .expect(201);

    // Verify API Response
    expect(response.body).toHaveProperty('id');
    expect(response.body.status).toBe('REQUESTED');
    expect(response.body.riderUserId).toBe('test-user-id');

    // Verify Socket Gateway emit was called with proper args
    expect(socketGateway.emitTripStatus).toHaveBeenCalledWith(
      response.body.id,
      'REQUESTED',
      expect.objectContaining({
        rideRequest: expect.objectContaining({ id: response.body.id }),
      }),
    );
  });

  it('/api/v1/ride-requests (POST) - fails with 401 when no token is provided', async () => {
    const payload = {
      pickupPoint: { type: 'Point', coordinates: [77.1, 28.1] },
      dropPoint: { type: 'Point', coordinates: [77.2, 28.2] },
      pickupAddress: 'Start Location',
      dropAddress: 'End Location',
      rideType: 'SOLO',
      vehicleType: 'AUTO',
    };

    await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      // No Authorization header
      .send(payload)
      .expect(401);
  });

  it('/api/v1/ride-requests (POST) - fails with 401 using an invalid token', async () => {
    const payload = {
      pickupPoint: { type: 'Point', coordinates: [77.1, 28.1] },
      dropPoint: { type: 'Point', coordinates: [77.2, 28.2] },
      pickupAddress: 'Start Location',
      dropAddress: 'End Location',
      rideType: 'SOLO',
      vehicleType: 'AUTO',
    };

    await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer expired-or-fake-token')
      .send(payload)
      .expect(401);
  });

  it('/api/v1/ride-requests (POST) - fails with 400 if user tries to requested duplicate', async () => {
    // Force findOne to return an existing ride to trigger the duplicate check
    const repo = app.get(getRepositoryToken(RideRequestEntity));
    jest.spyOn(repo, 'findOne').mockResolvedValueOnce({ id: 'active-ride' });

    const payload = {
      pickupPoint: { type: 'Point', coordinates: [77.1, 28.1] },
      dropPoint: { type: 'Point', coordinates: [77.2, 28.2] },
      pickupAddress: 'Start Location',
      dropAddress: 'End Location',
      rideType: 'SOLO',
      vehicleType: 'AUTO',
    };

    const res = await request(app.getHttpServer())
      .post('/api/v1/ride-requests')
      .set('Authorization', 'Bearer valid-token')
      .send(payload)
      .expect(400);

    expect(res.body.message).toBe('User already has an active ride request');
  });

  it('/api/v1/ride-requests/:id/accept (POST) - fails with 409 if already accepted', async () => {
    const dataSource = app.get(DataSource);
    const mockManager = dataSource.createQueryRunner().manager;
    jest.spyOn(mockManager, 'createQueryBuilder').mockReturnValueOnce({
      setLock: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      getOne: jest.fn().mockResolvedValue({ id: 'r1', status: 'ACCEPTED' }),
    } as any);

    await request(app.getHttpServer())
      .post('/api/v1/ride-requests/r1/accept')
      .set('Authorization', 'Bearer valid-token')
      .expect(409);
  });

  it('/api/v1/ride-requests/:id/cancel (PATCH) - cancels request & emits socket', async () => {
    jest.spyOn(socketGateway, 'emitTripStatus');

    await request(app.getHttpServer())
      .patch('/api/v1/ride-requests/req-id-123/cancel')
      .set('Authorization', 'Bearer valid-token')
      .expect(200);

    const repo = app.get(getRepositoryToken(RideRequestEntity));
    expect(repo.update).toHaveBeenCalledWith(
      { id: 'req-id-123', riderUserId: 'test-user-id' },
      { status: 'CANCELLED' }
    );

    expect(socketGateway.emitTripStatus).toHaveBeenCalledWith(
      'req-id-123',
      'CANCELLED',
      expect.objectContaining({ reason: 'Cancelled by rider' }),
    );
  });
});
