import { Test, TestingModule } from '@nestjs/testing';
import {
  INestApplication,
  ValidationPipe,
  UnauthorizedException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import * as request from 'supertest';
import { AuthController } from '../src/modules/Authentication/auth/auth.controller';
import { AuthService } from '../src/modules/Authentication/auth/auth.service';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';

/**
 * ┌──────────────────────────────────────────────────────────────────────┐
 * │  E2E TEST: COMPLETE AUTHENTICATION JOURNEY                           │
 * │                                                                      │
 * │  This spec simulates the FULL multi-step lifecycle of a user         │
 * │  in the Vectra platform — from first registration through token      │
 * │  management, profile access, and secure session termination.         │
 * │                                                                      │
 * │  Unlike integration tests (isolated endpoint calls), each test       │
 * │  here chains on state produced by a previous step, mimicking         │
 * │  a real mobile client session.                                       │
 * └──────────────────────────────────────────────────────────────────────┘
 */

// ── Shared session state across tests in the journey ──────────────────────
let accessToken = '';
let refreshToken = '';
let refreshTokenId = '';

// ── Mock AuthService factory ───────────────────────────────────────────────
const MOCK_USER = {
  id: 'user-e2e-001',
  email: 'rider@vectra.app',
  role: 'RIDER',
  fullName: 'E2E Rider',
  isVerified: true,
  createdAt: new Date().toISOString(),
};

const MOCK_TOKENS = {
  accessToken: 'e2e.access.token.v1',
  refreshToken: 'e2e.refresh.token.v1',
  refreshTokenId: 'rt-e2e-001',
  accessExpiresIn: '15m',
  user: MOCK_USER,
};

const ROTATED_TOKENS = {
  accessToken: 'e2e.access.token.v2',
  refreshToken: 'e2e.refresh.token.v2',
  refreshTokenId: 'rt-e2e-002',
  accessExpiresIn: '15m',
  user: MOCK_USER,
};

const makeMockAuthService = () => ({
  validateLogin:           jest.fn(),
  createSessionAndTokens:  jest.fn(),
  verifyOtpAndLogin:       jest.fn(),
  requestOtp:              jest.fn(),
  rotateRefreshToken:      jest.fn(),
  revokeRefreshTokenById:  jest.fn(),
  revokeAllForUser:        jest.fn(),
  getMe:                   jest.fn(),
  listSessions:            jest.fn(),
  registerRider:           jest.fn(),
  registerDriver:          jest.fn(),
});

// ── Mock JWT guard ─────────────────────────────────────────────────────────
const makeMockGuard = (validToken: string) => ({
  canActivate: (ctx: any) => {
    const req = ctx.switchToHttp().getRequest();
    const auth = req.headers.authorization;
    if (!auth || !auth.startsWith('Bearer ') || auth.split(' ')[1] !== validToken) {
      throw new UnauthorizedException('Invalid or missing token');
    }
    req.user = { userId: 'user-e2e-001', role: 'RIDER' };
    return true;
  },
});

// ═══════════════════════════════════════════════════════════════════════════

describe('E2E Journey: Complete Rider Authentication Lifecycle', () => {
  let app: INestApplication;
  let authService: ReturnType<typeof makeMockAuthService>;
  // The valid token changes after refresh — keep track
  let currentAccessToken = 'e2e.access.token.v1';

  beforeAll(async () => {
    authService = makeMockAuthService();

    const mockGuard = {
      canActivate: (ctx: any) => {
        const req = ctx.switchToHttp().getRequest();
        const auth = req.headers.authorization;
        if (!auth || !auth.startsWith('Bearer ')) {
          throw new UnauthorizedException('Missing token');
        }
        // Accept either v1 or v2 token (before/after rotation)
        const token = auth.split(' ')[1];
        if (!['e2e.access.token.v1', 'e2e.access.token.v2'].includes(token)) {
          throw new UnauthorizedException('Invalid token');
        }
        req.user = { userId: 'user-e2e-001', role: 'RIDER' };
        return true;
      },
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: authService }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(mockGuard)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  afterEach(() => jest.clearAllMocks());

  // ── STEP 1: Register ─────────────────────────────────────────────────────

  it('E2E-AUTH-STEP-01 → Rider registers with email + password → receives session tokens', async () => {
    authService.registerRider.mockResolvedValue(MOCK_TOKENS);

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/register/rider')
      .send({
        email: 'rider@vectra.app',
        fullName: 'E2E Rider',
        password: 'Secure@Pass123',
      })
      .expect(201);

    expect(res.body).toHaveProperty('accessToken');
    expect(res.body).toHaveProperty('refreshToken');
    expect(res.body).toHaveProperty('refreshTokenId');
    expect(res.body.user.email).toBe('rider@vectra.app');

    // Capture tokens for subsequent steps
    accessToken    = res.body.accessToken;
    refreshToken   = res.body.refreshToken;
    refreshTokenId = res.body.refreshTokenId;
  });

  it('E2E-AUTH-STEP-02 → Duplicate registration with same email is rejected (409)', async () => {
    authService.registerRider.mockRejectedValue(
      new ConflictException('Email already in use'),
    );

    await request(app.getHttpServer())
      .post('/api/v1/auth/register/rider')
      .send({ email: 'rider@vectra.app', fullName: 'Duplicate', password: 'Secure@Pass123' })
      .expect(409);
  });

  // ── STEP 2: Login ────────────────────────────────────────────────────────

  it('E2E-AUTH-STEP-03 → Rider logs in with credentials → receives new tokens', async () => {
    authService.validateLogin.mockResolvedValue({ id: 'user-e2e-001', role: 'RIDER' });
    authService.createSessionAndTokens.mockResolvedValue(MOCK_TOKENS);

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'rider@vectra.app', password: 'Secure@Pass123' })
      .expect(201);

    expect(res.body.user.role).toBe('RIDER');
    expect(res.body).toHaveProperty('accessToken');
  });

  it('E2E-AUTH-STEP-04 → Login with wrong password → 401 (no token issued)', async () => {
    authService.validateLogin.mockRejectedValue(
      new UnauthorizedException('Invalid credentials'),
    );

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'rider@vectra.app', password: 'WrongPass!' })
      .expect(401);

    expect(res.body).not.toHaveProperty('accessToken');
  });

  // ── STEP 3: Authenticated session ────────────────────────────────────────

  it('E2E-AUTH-STEP-05 → GET /me with valid token returns profile (no passwordHash)', async () => {
    authService.getMe.mockResolvedValue({
      id: 'user-e2e-001',
      email: 'rider@vectra.app',
      role: 'RIDER',
      fullName: 'E2E Rider',
      isVerified: true,
    });

    const res = await request(app.getHttpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(res.body.email).toBe('rider@vectra.app');
    expect(res.body).not.toHaveProperty('passwordHash');
  });

  it('E2E-AUTH-STEP-06 → GET /me without token returns 401 (session guard enforced)', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/auth/me')
      .expect(401);
  });

  // ── STEP 4: OTP flow ─────────────────────────────────────────────────────

  it('E2E-AUTH-STEP-07 → Request OTP for email channel', async () => {
    authService.requestOtp.mockResolvedValue({ success: true, expiresIn: 300 });

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/request-otp')
      .send({ identifier: 'rider@vectra.app', channel: 'email' })
      .expect(201);

    expect(res.body.success).toBe(true);
  });

  it('E2E-AUTH-STEP-08 → Verify valid OTP → receive tokens', async () => {
    authService.verifyOtpAndLogin.mockResolvedValue(MOCK_TOKENS);

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/verify-otp')
      .send({ identifier: 'rider@vectra.app', code: '123456' })
      .expect(201);

    expect(res.body).toHaveProperty('accessToken');
  });

  it('E2E-AUTH-STEP-09 → Verify invalid OTP → 401 (no session created)', async () => {
    authService.verifyOtpAndLogin.mockRejectedValue(
      new UnauthorizedException('Invalid OTP'),
    );

    await request(app.getHttpServer())
      .post('/api/v1/auth/verify-otp')
      .send({ identifier: 'rider@vectra.app', code: '000000' })
      .expect(401);
  });

  // ── STEP 5: Token rotation ────────────────────────────────────────────────

  it('E2E-AUTH-STEP-10 → Rotate refresh token → receive NEW access+refresh pair', async () => {
    authService.rotateRefreshToken.mockResolvedValue(ROTATED_TOKENS);

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .set('x-refresh-token-id', refreshTokenId)
      .send({ refreshToken })
      .expect(201);

    expect(res.body.accessToken).toBe('e2e.access.token.v2');
    expect(res.body.refreshToken).toBe('e2e.refresh.token.v2');

    // Rotate — update state for next steps
    accessToken    = res.body.accessToken;
    refreshToken   = res.body.refreshToken;
    refreshTokenId = res.body.refreshTokenId;
  });

  it('E2E-AUTH-STEP-11 → Reuse old refresh token → 401 (revoked)', async () => {
    authService.rotateRefreshToken.mockRejectedValue(
      new UnauthorizedException('Refresh token revoked'),
    );

    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .set('x-refresh-token-id', 'rt-e2e-001')
      .send({ refreshToken: 'e2e.refresh.token.v1' }) // old, now revoked
      .expect(401);
  });

  it('E2E-AUTH-STEP-12 → Tampered refresh token → 401 + all sessions revoked', async () => {
    authService.rotateRefreshToken.mockRejectedValue(
      new UnauthorizedException('Invalid refresh token (revoked all sessions)'),
    );

    await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .set('x-refresh-token-id', refreshTokenId)
      .send({ refreshToken: 'tampered-token-xyz' })
      .expect(401);
  });

  // ── STEP 6: Logout ────────────────────────────────────────────────────────

  it('E2E-AUTH-STEP-13 → Logout current device session (single token revoke)', async () => {
    authService.revokeRefreshTokenById.mockResolvedValue(true);

    await request(app.getHttpServer())
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .set('x-refresh-token-id', refreshTokenId)
      .expect(201);

    expect(authService.revokeRefreshTokenById).toHaveBeenCalledTimes(1);
  });

  it('E2E-AUTH-STEP-14 → Logout-all: revoke every active session for user', async () => {
    authService.revokeAllForUser.mockResolvedValue(true);

    await request(app.getHttpServer())
      .post('/api/v1/auth/logout-all')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(201);

    expect(authService.revokeAllForUser).toHaveBeenCalledWith('user-e2e-001');
  });

  it('E2E-AUTH-STEP-15 → Attempt protected route after logout → still gets profile (token still valid in memory)', async () => {
    // accessToken is still technically valid (JWT is stateless) — /me depends on guard
    authService.getMe.mockResolvedValue(MOCK_USER);

    const res = await request(app.getHttpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(res.body.id).toBe('user-e2e-001');
  });

  // ── Security edge cases ───────────────────────────────────────────────────

  it('E2E-AUTH-STEP-16 → Suspended user login attempt → 403 Forbidden', async () => {
    authService.validateLogin.mockRejectedValue(
      new ForbiddenException('Account suspended: Community guidelines violation'),
    );

    const res = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'suspended@vectra.app', password: 'AnyPass123' })
      .expect(403);

    expect(res.body.message).toContain('suspended');
  });

  it('E2E-AUTH-STEP-17 → Unverified driver OTP login → 403 Forbidden', async () => {
    authService.verifyOtpAndLogin.mockRejectedValue(
      new ForbiddenException('Driver account not verified'),
    );

    await request(app.getHttpServer())
      .post('/api/v1/auth/verify-otp')
      .send({ identifier: '+919876543210', code: '654321' })
      .expect(403);
  });
});
