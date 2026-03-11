import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UnauthorizedException, BadRequestException, ForbiddenException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { OtpService } from './otp.service';
import { UsersService } from '../users/users.service';
import { UserEntity, UserRole } from '../users/user.entity';
import { RefreshTokenEntity } from './refresh-token.entity';
import { DriverProfileEntity, DriverStatus } from '../drivers/driver-profile.entity';

// ── Helpers ────────────────────────────────────────────────────────────────

const mockUser = (overrides: Partial<UserEntity> = {}): UserEntity =>
  ({
    id: 'user-uuid-1',
    role: UserRole.RIDER,
    email: 'test@example.com',
    phone: null,
    fullName: 'Test User',
    passwordHash: null,
    isVerified: true,
    isSuspended: false,
    suspensionReason: null,
    status: 'active',
    lastLoginAt: null,
    createdAt: new Date('2024-01-01'),
    rideRequests: [],
    driverTrips: [],
    tripRiders: [],
    ...overrides,
  } as UserEntity);

const mockRefreshToken = (overrides: Partial<RefreshTokenEntity> = {}): RefreshTokenEntity =>
  ({
    id: 'rt-uuid-1',
    userId: 'user-uuid-1',
    tokenHash: 'hashed-token',
    deviceInfo: 'iPhone 15',
    ip: '127.0.0.1',
    revokedAt: null,
    expiresAt: new Date(Date.now() + 7 * 24 * 3600 * 1000),
    lastUsedAt: new Date(),
    createdAt: new Date(),
    ...overrides,
  } as RefreshTokenEntity);

const mockDriverProfile = (overrides: Partial<DriverProfileEntity> = {}): DriverProfileEntity =>
  ({
    id: 'dp-uuid-1',
    userId: 'user-uuid-1',
    status: DriverStatus.VERIFIED,
    ...overrides,
  } as DriverProfileEntity);

// ── Repo mock factory ──────────────────────────────────────────────────────

const makeRepo = () => ({
  findOne: jest.fn(),
  find: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
});

// ── Tests ──────────────────────────────────────────────────────────────────

describe('AuthService', () => {
  let service: AuthService;
  let jwtService: jest.Mocked<JwtService>;
  let otpService: jest.Mocked<OtpService>;
  let usersRepo: ReturnType<typeof makeRepo>;
  let refreshRepo: ReturnType<typeof makeRepo>;
  let profilesRepo: ReturnType<typeof makeRepo>;

  beforeEach(async () => {
    usersRepo = makeRepo();
    refreshRepo = makeRepo();
    profilesRepo = makeRepo();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: JwtService,
          useValue: { sign: jest.fn().mockReturnValue('mock.jwt.token') },
        },
        {
          provide: OtpService,
          useValue: {
            requestOtp: jest.fn(),
            verifyOtp: jest.fn(),
          },
        },
        { provide: getRepositoryToken(UserEntity), useValue: usersRepo },
        { provide: getRepositoryToken(RefreshTokenEntity), useValue: refreshRepo },
        { provide: getRepositoryToken(DriverProfileEntity), useValue: profilesRepo },
        {
          provide: UsersService,
          useValue: {
            createRider: jest.fn(),
            createDriver: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    jwtService = module.get(JwtService);
    otpService = module.get(OtpService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── parseExpiryToSeconds (private, tested via createSessionAndTokens) ───

  describe('requestOtp', () => {
    it('delegates to OtpService', async () => {
      otpService.requestOtp.mockResolvedValue({ success: true } as any);
      const result = await service.requestOtp('email', 'test@example.com');
      expect(otpService.requestOtp).toHaveBeenCalledWith('email', 'test@example.com');
      expect(result).toEqual({ success: true });
    });
  });

  // ── verifyOtpAndLogin ────────────────────────────────────────────────────

  describe('verifyOtpAndLogin', () => {
    it('throws UnauthorizedException when OTP is invalid', async () => {
      otpService.verifyOtp.mockResolvedValue(false);
      await expect(
        service.verifyOtpAndLogin('test@example.com', 'wrong-otp'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('creates a new user when email is not found and returns tokens', async () => {
      otpService.verifyOtp.mockResolvedValue(true);
      usersRepo.findOne.mockResolvedValue(null);
      const newUser = mockUser({ isVerified: true });
      usersRepo.create.mockReturnValue(newUser);
      usersRepo.save.mockResolvedValue(newUser);

      const rt = mockRefreshToken();
      refreshRepo.create.mockReturnValue(rt);
      refreshRepo.save.mockResolvedValue(rt);

      const result = await service.verifyOtpAndLogin('test@example.com', '123456');

      expect(usersRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ email: 'test@example.com', role: UserRole.RIDER }),
      );
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('test@example.com');
    });

    it('logs in an existing verified user', async () => {
      otpService.verifyOtp.mockResolvedValue(true);
      const existing = mockUser({ isVerified: true });
      usersRepo.findOne.mockResolvedValue(existing);
      usersRepo.save.mockResolvedValue(existing);

      const rt = mockRefreshToken();
      refreshRepo.create.mockReturnValue(rt);
      refreshRepo.save.mockResolvedValue(rt);

      const result = await service.verifyOtpAndLogin('test@example.com', '123456');
      expect(result.user.id).toBe('user-uuid-1');
    });

    it('marks an unverified existing user as verified', async () => {
      otpService.verifyOtp.mockResolvedValue(true);
      const existing = mockUser({ isVerified: false });
      usersRepo.findOne.mockResolvedValue(existing);
      usersRepo.save.mockResolvedValue({ ...existing, isVerified: true });

      const rt = mockRefreshToken();
      refreshRepo.create.mockReturnValue(rt);
      refreshRepo.save.mockResolvedValue(rt);

      await service.verifyOtpAndLogin('test@example.com', '123456');
      // save should be called to set isVerified = true
      expect(usersRepo.save).toHaveBeenCalled();
    });

    it('throws ForbiddenException for unverified driver', async () => {
      otpService.verifyOtp.mockResolvedValue(true);
      const driverUser = mockUser({ role: UserRole.DRIVER });
      usersRepo.findOne.mockResolvedValue(driverUser);
      usersRepo.save.mockResolvedValue(driverUser);
      profilesRepo.findOne.mockResolvedValue(mockDriverProfile({ status: DriverStatus.PENDING_VERIFICATION }));

      await expect(
        service.verifyOtpAndLogin('+919876543210', '123456'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('allows login for verified driver', async () => {
      otpService.verifyOtp.mockResolvedValue(true);
      const driverUser = mockUser({ role: UserRole.DRIVER });
      usersRepo.findOne.mockResolvedValue(driverUser);
      usersRepo.save.mockResolvedValue(driverUser);
      profilesRepo.findOne.mockResolvedValue(mockDriverProfile({ status: DriverStatus.VERIFIED }));

      const rt = mockRefreshToken();
      refreshRepo.create.mockReturnValue(rt);
      refreshRepo.save.mockResolvedValue(rt);

      const result = await service.verifyOtpAndLogin('+919876543210', '123456');
      expect(result).toHaveProperty('accessToken');
    });
  });

  // ── validateLogin ────────────────────────────────────────────────────────

  describe('validateLogin', () => {
    it('throws BadRequestException when no credentials provided', async () => {
      await expect(service.validateLogin()).rejects.toThrow(BadRequestException);
    });

    it('throws UnauthorizedException when user not found', async () => {
      usersRepo.findOne.mockResolvedValue(null);
      await expect(
        service.validateLogin('notfound@example.com', undefined, 'password123'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws ForbiddenException for suspended user', async () => {
      usersRepo.findOne.mockResolvedValue(
        mockUser({ isSuspended: true, suspensionReason: 'Policy violation' }),
      );
      await expect(
        service.validateLogin('test@example.com', undefined, 'password123'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws UnauthorizedException when password hash is missing', async () => {
      usersRepo.findOne.mockResolvedValue(mockUser({ passwordHash: null }));
      await expect(
        service.validateLogin('test@example.com', undefined, 'password123'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException when password is wrong', async () => {
      const hashed = await bcrypt.hash('correct-password', 10);
      usersRepo.findOne.mockResolvedValue(mockUser({ passwordHash: hashed }));
      await expect(
        service.validateLogin('test@example.com', undefined, 'wrong-password'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('returns user when password is correct', async () => {
      const hashed = await bcrypt.hash('correct-password', 10);
      const user = mockUser({ passwordHash: hashed });
      usersRepo.findOne.mockResolvedValue(user);

      const result = await service.validateLogin('test@example.com', undefined, 'correct-password');
      expect(result.id).toBe('user-uuid-1');
    });

    it('returns user when OTP is valid', async () => {
      otpService.verifyOtp.mockResolvedValue(true);
      const user = mockUser();
      usersRepo.findOne.mockResolvedValue(user);
      usersRepo.save.mockResolvedValue(user);

      const result = await service.validateLogin('test@example.com', undefined, undefined, '123456');
      expect(result.id).toBe('user-uuid-1');
    });

    it('throws UnauthorizedException when OTP is invalid in validateLogin', async () => {
      otpService.verifyOtp.mockResolvedValue(false);
      usersRepo.findOne.mockResolvedValue(mockUser());

      await expect(
        service.validateLogin('test@example.com', undefined, undefined, 'wrong-otp'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  // ── createSessionAndTokens ───────────────────────────────────────────────

  describe('createSessionAndTokens', () => {
    it('creates access + refresh tokens and saves refresh token to DB', async () => {
      const user = mockUser();
      const rt = mockRefreshToken();
      refreshRepo.create.mockReturnValue(rt);
      refreshRepo.save.mockResolvedValue(rt);

      const result = await service.createSessionAndTokens(user, 'Android', '1.2.3.4');

      expect(jwtService.sign).toHaveBeenCalledTimes(2);
      expect(refreshRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'user-uuid-1', deviceInfo: 'Android', ip: '1.2.3.4' }),
      );
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result).toHaveProperty('refreshTokenId');
    });

    it('stores a bcrypt hash of the refresh token, not the raw token', async () => {
      const user = mockUser();
      let capturedCreateArg: any;
      refreshRepo.create.mockImplementation((data) => {
        capturedCreateArg = data;
        return data;
      });
      refreshRepo.save.mockImplementation((data) => Promise.resolve({ ...data, id: 'rt-uuid-1' }));

      const result = await service.createSessionAndTokens(user);

      const rawToken = result.refreshToken;
      const isHashed = await bcrypt.compare(rawToken, capturedCreateArg.tokenHash);
      expect(isHashed).toBe(true);
    });
  });

  // ── rotateRefreshToken ───────────────────────────────────────────────────

  describe('rotateRefreshToken', () => {
    it('throws UnauthorizedException when record not found', async () => {
      refreshRepo.findOne.mockResolvedValue(null);
      await expect(
        service.rotateRefreshToken('raw-token', 'nonexistent-id'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException when token is revoked', async () => {
      refreshRepo.findOne.mockResolvedValue(mockRefreshToken({ revokedAt: new Date() }));
      await expect(
        service.rotateRefreshToken('raw-token', 'rt-uuid-1'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('throws UnauthorizedException when token is expired', async () => {
      refreshRepo.findOne.mockResolvedValue(
        mockRefreshToken({ expiresAt: new Date(Date.now() - 1000) }),
      );
      await expect(
        service.rotateRefreshToken('raw-token', 'rt-uuid-1'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('revokes all sessions on token hash mismatch (theft detection)', async () => {
      const hashed = await bcrypt.hash('real-token', 10);
      refreshRepo.findOne.mockResolvedValue(mockRefreshToken({ tokenHash: hashed }));

      await expect(
        service.rotateRefreshToken('tampered-token', 'rt-uuid-1'),
      ).rejects.toThrow(UnauthorizedException);

      expect(refreshRepo.update).toHaveBeenCalledWith(
        { userId: 'user-uuid-1' },
        { revokedAt: expect.any(Date) },
      );
    });

    it('issues new tokens on valid rotation', async () => {
      const rawToken = 'valid-raw-token';
      const hashed = await bcrypt.hash(rawToken, 10);
      const rt = mockRefreshToken({ tokenHash: hashed });
      refreshRepo.findOne.mockResolvedValueOnce(rt);
      refreshRepo.save.mockResolvedValue(rt);

      const user = mockUser();
      usersRepo.findOne.mockResolvedValue(user);

      const newRt = mockRefreshToken({ id: 'rt-uuid-2' });
      refreshRepo.create.mockReturnValue(newRt);
      refreshRepo.save.mockResolvedValue(newRt);

      const result = await service.rotateRefreshToken(rawToken, 'rt-uuid-1');
      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
    });
  });

  // ── revokeRefreshTokenById ───────────────────────────────────────────────

  describe('revokeRefreshTokenById', () => {
    it('returns false when token not found', async () => {
      refreshRepo.findOne.mockResolvedValue(null);
      const result = await service.revokeRefreshTokenById('nonexistent');
      expect(result).toBe(false);
    });

    it('throws when userId does not match', async () => {
      refreshRepo.findOne.mockResolvedValue(mockRefreshToken({ userId: 'other-user' }));
      await expect(
        service.revokeRefreshTokenById('rt-uuid-1', 'user-uuid-1'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('revokes and returns true when user matches', async () => {
      const rt = mockRefreshToken();
      refreshRepo.findOne.mockResolvedValue(rt);
      refreshRepo.save.mockResolvedValue({ ...rt, revokedAt: new Date() });

      const result = await service.revokeRefreshTokenById('rt-uuid-1', 'user-uuid-1');
      expect(result).toBe(true);
      expect(refreshRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({ revokedAt: expect.any(Date) }),
      );
    });
  });

  // ── revokeAllForUser ────────────────────────────────────────────────────

  describe('revokeAllForUser', () => {
    it('updates all tokens for the user and returns true', async () => {
      refreshRepo.update.mockResolvedValue({ affected: 3 } as any);
      const result = await service.revokeAllForUser('user-uuid-1');
      expect(result).toBe(true);
      expect(refreshRepo.update).toHaveBeenCalledWith(
        { userId: 'user-uuid-1' },
        { revokedAt: expect.any(Date) },
      );
    });
  });

  // ── getMe ────────────────────────────────────────────────────────────────

  describe('getMe', () => {
    it('returns public user fields when found', async () => {
      usersRepo.findOne.mockResolvedValue(mockUser());
      const result = await service.getMe('user-uuid-1');
      expect(result).toMatchObject({
        id: 'user-uuid-1',
        email: 'test@example.com',
        role: UserRole.RIDER,
      });
      // password hash must NOT be exposed
      expect(result).not.toHaveProperty('passwordHash');
    });

    it('throws UnauthorizedException when user not found', async () => {
      usersRepo.findOne.mockResolvedValue(null);
      await expect(service.getMe('ghost-uuid')).rejects.toThrow(UnauthorizedException);
    });
  });

  // ── validateJwtPayload ───────────────────────────────────────────────────

  describe('validateJwtPayload', () => {
    it('returns null for empty payload', async () => {
      const result = await service.validateJwtPayload(null as any);
      expect(result).toBeNull();
    });

    it('returns null for suspended user', async () => {
      usersRepo.findOne.mockResolvedValue(mockUser({ isSuspended: true }));
      const result = await service.validateJwtPayload({ sub: 'user-uuid-1', role: 'RIDER' });
      expect(result).toBeNull();
    });

    it('returns user entity for a valid active user', async () => {
      const user = mockUser();
      usersRepo.findOne.mockResolvedValue(user);
      const result = await service.validateJwtPayload({ sub: 'user-uuid-1', role: 'RIDER' });
      expect(result?.id).toBe('user-uuid-1');
    });
  });
});
