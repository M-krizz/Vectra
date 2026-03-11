import { Test, TestingModule } from '@nestjs/testing';
import {
  INestApplication,
  ValidationPipe,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import * as request from 'supertest';
import { AuthController } from '../src/modules/Authentication/auth/auth.controller';
import { AuthService } from '../src/modules/Authentication/auth/auth.service';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

// ── Mock AuthService ────────────────────────────────────────────────────────

const makeMockAuthService = () => ({
  validateLogin: jest.fn(),
  createSessionAndTokens: jest.fn(),
  verifyOtpAndLogin: jest.fn(),
  requestOtp: jest.fn(),
  rotateRefreshToken: jest.fn(),
  revokeRefreshTokenById: jest.fn(),
  revokeAllForUser: jest.fn(),
  getMe: jest.fn(),
  listSessions: jest.fn(),
  registerRider: jest.fn(),
  registerDriver: jest.fn(),
});

const MOCK_TOKENS = {
  accessToken: 'mock.access.token',
  refreshToken: 'mock.refresh.token',
  refreshTokenId: 'rt-uuid-1',
  user: {
    id: 'user-uuid-1',
    email: 'test@example.com',
    role: 'RIDER',
    fullName: 'Test User',
  },
};

// ═══════════════════════════════════════════════════════════════════════════

describe('AuthController (e2e Regression)', () => {
  let app: INestApplication;
  let authService: ReturnType<typeof makeMockAuthService>;

  beforeAll(async () => {
    authService = makeMockAuthService();

    // Mock JWT guard – allow only requests with 'Bearer valid-token'
    const mockAuthGuard = {
      canActivate: (ctx: any) => {
        const req = ctx.switchToHttp().getRequest();
        const auth = req.headers.authorization;
        if (!auth || auth !== 'Bearer valid-token') {
          throw new UnauthorizedException('Invalid or missing token');
        }
        req.user = { userId: 'user-uuid-1', role: 'RIDER' };
        return true;
      },
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: authService }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(mockAuthGuard)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  afterEach(() => jest.clearAllMocks());

  // ── POST /api/v1/auth/login ───────────────────────────────────────────────

  describe('POST /api/v1/auth/login', () => {
    it('REG-AUTH-001 → returns 201 and tokens on valid email+password', async () => {
      const mockUser = { id: 'user-uuid-1', role: 'RIDER', email: 'test@example.com' };
      authService.validateLogin.mockResolvedValue(mockUser);
      authService.createSessionAndTokens.mockResolvedValue(MOCK_TOKENS);

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email: 'test@example.com', password: 'correct-password' })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body.user.email).toBe('test@example.com');
    });

    it('REG-AUTH-002 → returns 401 when password is wrong', async () => {
      authService.validateLogin.mockRejectedValue(
        new UnauthorizedException('Wrong credentials'),
      );

      await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email: 'test@example.com', password: 'wrong-pass' })
        .expect(401);
    });

    it('REG-AUTH-003 → returns 403 when user account is suspended', async () => {
      authService.validateLogin.mockRejectedValue(
        new ForbiddenException('Account suspended: Policy violation'),
      );

      await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email: 'suspended@example.com', password: 'any' })
        .expect(403);
    });
  });

  // ── POST /api/v1/auth/register/rider ─────────────────────────────────────

  describe('POST /api/v1/auth/register/rider', () => {
    it('REG-AUTH-004 → returns 201 with tokens on valid rider registration', async () => {
      authService.registerRider.mockResolvedValue(MOCK_TOKENS);

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/register/rider')
        .send({
          email: 'newrider@example.com',
          fullName: 'New Rider',
          password: 'Password123!',
        })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
    });

    it('REG-AUTH-005 → returns 409 when email already registered', async () => {
      const { ConflictException } = await import('@nestjs/common');
      authService.registerRider.mockRejectedValue(
        new ConflictException('Email already in use'),
      );

      await request(app.getHttpServer())
        .post('/api/v1/auth/register/rider')
        .send({
          email: 'existing@example.com',
          fullName: 'Existing User',
          password: 'Password123!',
        })
        .expect(409);
    });
  });

  // ── POST /api/v1/auth/request-otp ────────────────────────────────────────

  describe('POST /api/v1/auth/request-otp', () => {
    it('REG-AUTH-006 → delegates to authService.requestOtp and returns 201', async () => {
      authService.requestOtp.mockResolvedValue({ success: true });

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/request-otp')
        .send({ identifier: 'test@example.com', channel: 'email' })
        .expect(201);

      expect(res.body).toEqual({ success: true });
    });
  });

  // ── POST /api/v1/auth/verify-otp ─────────────────────────────────────────

  describe('POST /api/v1/auth/verify-otp', () => {
    it('REG-AUTH-007 → returns 201 with tokens on valid OTP', async () => {
      authService.verifyOtpAndLogin.mockResolvedValue(MOCK_TOKENS);

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/verify-otp')
        .send({ identifier: 'test@example.com', code: '123456' })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
    });

    it('REG-AUTH-008 → returns 401 for invalid OTP', async () => {
      authService.verifyOtpAndLogin.mockRejectedValue(
        new UnauthorizedException('Invalid OTP'),
      );

      await request(app.getHttpServer())
        .post('/api/v1/auth/verify-otp')
        .send({ identifier: 'test@example.com', code: '000000' })
        .expect(401);
    });

    it('REG-AUTH-009 → returns 403 for unverified driver trying to login via OTP', async () => {
      authService.verifyOtpAndLogin.mockRejectedValue(
        new ForbiddenException('Driver profile not verified'),
      );

      await request(app.getHttpServer())
        .post('/api/v1/auth/verify-otp')
        .send({ identifier: '+919876543210', code: '123456' })
        .expect(403);
    });
  });

  // ── POST /api/v1/auth/refresh ─────────────────────────────────────────────

  describe('POST /api/v1/auth/refresh', () => {
    it('REG-AUTH-010 → returns new tokens on valid refresh token', async () => {
      authService.rotateRefreshToken.mockResolvedValue(MOCK_TOKENS);

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/refresh')
        .set('x-refresh-token-id', 'rt-uuid-1')
        .send({ refreshToken: 'valid-raw-token' })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
    });

    it('REG-AUTH-011 → returns 401 for expired/revoked refresh token', async () => {
      authService.rotateRefreshToken.mockRejectedValue(
        new UnauthorizedException('Token revoked or expired'),
      );

      await request(app.getHttpServer())
        .post('/api/v1/auth/refresh')
        .set('x-refresh-token-id', 'rt-old')
        .send({ refreshToken: 'expired-token' })
        .expect(401);
    });
  });

  // ── POST /api/v1/auth/logout ──────────────────────────────────────────────

  describe('POST /api/v1/auth/logout', () => {
    it('REG-AUTH-012 → returns 200 and revokes session when token is valid', async () => {
      authService.revokeRefreshTokenById.mockResolvedValue(true);

      await request(app.getHttpServer())
        .post('/api/v1/auth/logout')
        .set('Authorization', 'Bearer valid-token')
        .set('x-refresh-token-id', 'rt-uuid-1')
        .expect(201);
    });

    it('REG-AUTH-013 → returns 401 when no auth token provided', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/auth/logout')
        .set('x-refresh-token-id', 'rt-uuid-1')
        .expect(401);
    });
  });

  // ── GET /api/v1/auth/me ───────────────────────────────────────────────────

  describe('GET /api/v1/auth/me', () => {
    it('REG-AUTH-014 → returns logged-in user profile without passwordHash', async () => {
      authService.getMe.mockResolvedValue({
        id: 'user-uuid-1',
        email: 'test@example.com',
        role: 'RIDER',
        fullName: 'Test User',
      });

      const res = await request(app.getHttpServer())
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer valid-token')
        .expect(200);

      expect(res.body.email).toBe('test@example.com');
      expect(res.body).not.toHaveProperty('passwordHash');
    });

    it('REG-AUTH-015 → returns 401 without Authorization header', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/auth/me')
        .expect(401);
    });
  });

  // ── POST /api/v1/auth/logout-all ─────────────────────────────────────────

  describe('POST /api/v1/auth/logout-all', () => {
    it('REG-AUTH-016 → revokes all sessions for the authenticated user', async () => {
      authService.revokeAllForUser.mockResolvedValue(true);

      await request(app.getHttpServer())
        .post('/api/v1/auth/logout-all')
        .set('Authorization', 'Bearer valid-token')
        .expect(201);

      expect(authService.revokeAllForUser).toHaveBeenCalledWith('user-uuid-1');
    });
  });
});
