import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { getRepositoryToken } from '@nestjs/typeorm';
import { TripsController } from '../src/modules/trips/trips.controller';
import { TripsService } from '../src/modules/trips/trips.service';
import { RealtimeModule } from '../src/realtime/realtime.module';
import { TripEntity } from '../src/modules/trips/trip.entity';
import { TripEventEntity } from '../src/modules/trips/trip-event.entity';
import { SocketGateway } from '../src/realtime/socket.gateway';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

describe('TripsController (e2e)', () => {
  let app: INestApplication;
  let socketGateway: SocketGateway;

  beforeAll(async () => {
    // Mock guards to simulate authenticated driver
    const mockAuthGuard = {
      canActivate: (context: any) => {
        const req = context.switchToHttp().getRequest();
        req.user = { userId: 'test-driver-id', role: 'driver' };
        return true;
      },
    };

    const mockTripRepo = {
      findOne: jest.fn().mockImplementation(() => Promise.resolve({ id: 'trip-123' })),
    };

    const mockEventRepo = {
      create: jest.fn().mockImplementation((dto) => ({ id: 'event-123', ...dto })),
      save: jest.fn().mockImplementation((entity) => Promise.resolve(entity)),
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [RealtimeModule],
      controllers: [TripsController],
      providers: [
        TripsService,
        {
          provide: getRepositoryToken(TripEntity),
          useValue: mockTripRepo,
        },
        {
          provide: getRepositoryToken(TripEventEntity),
          useValue: mockEventRepo,
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

  it('/api/v1/trips/:id/location (PATCH) - saves event & emits socket', async () => {
    jest.spyOn(socketGateway, 'emitLocationUpdate');

    const payload = {
      lat: 28.5,
      lng: 77.5,
    };

    const response = await request(app.getHttpServer())
      .patch('/api/v1/trips/trip-123/location')
      .send(payload)
      .expect(200);

    // Verify Socket Gateway emit was called with the correct args
    expect(socketGateway.emitLocationUpdate).toHaveBeenCalledWith(
      'trip-123',
      payload.lat,
      payload.lng,
    );
  });
});
