import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import {
    UnauthorizedException,
    BadRequestException,
    ForbiddenException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { OtpService } from './otp.service';
import { UserEntity, UserRole } from '../users/user.entity';
import { RefreshTokenEntity } from './refresh-token.entity';
import { DriverProfileEntity, DriverStatus } from '../drivers/driver-profile.entity';

// Mock bcrypt
jest.mock('bcrypt', () => ({
    compare: jest.fn(),
    hash: jest.fn(),
}));

describe('AuthService', () => {
    let service: AuthService;
    let usersRepo: any;
    let refreshRepo: any;
    let profilesRepo: any;
    let jwtService: any;
    let otpService: any;

    const mockUser: Partial<UserEntity> = {
        id: 'user-123',
        email: 'test@example.com',
        phone: '+919876543210',
        passwordHash: 'hashed-password',
        role: UserRole.RIDER,
        isVerified: true,
        isSuspended: false,
        lastLoginAt: null,
    };

    const mockDriverUser: Partial<UserEntity> = {
        ...mockUser,
        id: 'driver-123',
        role: UserRole.DRIVER,
    };

    beforeEach(async () => {
        // Reset all mocks
        jest.clearAllMocks();

        const module: TestingModule = await Test.createTestingModule({
            providers: [
                AuthService,
                {
                    provide: JwtService,
                    useValue: {
                        sign: jest.fn().mockReturnValue('mock-jwt-token'),
                    },
                },
                {
                    provide: OtpService,
                    useValue: {
                        requestOtp: jest.fn(),
                        verifyOtp: jest.fn(),
                    },
                },
                {
                    provide: getRepositoryToken(UserEntity),
                    useValue: {
                        findOne: jest.fn(),
                        create: jest.fn(),
                        save: jest.fn(),
                    },
                },
                {
                    provide: getRepositoryToken(RefreshTokenEntity),
                    useValue: {
                        findOne: jest.fn(),
                        create: jest.fn(),
                        save: jest.fn(),
                        delete: jest.fn(),
                        update: jest.fn(),
                        find: jest.fn(),
                    },
                },
                {
                    provide: getRepositoryToken(DriverProfileEntity),
                    useValue: {
                        findOne: jest.fn(),
                    },
                },
            ],
        }).compile();

        service = module.get<AuthService>(AuthService);
        usersRepo = module.get(getRepositoryToken(UserEntity));
        refreshRepo = module.get(getRepositoryToken(RefreshTokenEntity));
        profilesRepo = module.get(getRepositoryToken(DriverProfileEntity));
        jwtService = module.get(JwtService);
        otpService = module.get(OtpService);
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    // ===============================
    // requestOtp
    // ===============================
    describe('requestOtp', () => {
        it('should delegate to OtpService.requestOtp', async () => {
            const expectedResult = { success: true, channel: 'phone', identifier: '+919876543210' };
            otpService.requestOtp.mockResolvedValue(expectedResult);

            const result = await service.requestOtp('phone', '+919876543210');

            expect(otpService.requestOtp).toHaveBeenCalledWith('phone', '+919876543210');
            expect(result).toEqual(expectedResult);
        });
    });

    // ===============================
    // validateLogin
    // ===============================
    describe('validateLogin', () => {
        it('should throw BadRequestException if no email/phone provided', async () => {
            await expect(
                service.validateLogin(undefined, undefined, 'password123'),
            ).rejects.toThrow(BadRequestException);
        });

        it('should throw BadRequestException if no password or otp provided', async () => {
            await expect(
                service.validateLogin('test@example.com', undefined, undefined, undefined),
            ).rejects.toThrow(BadRequestException);
        });

        it('should throw UnauthorizedException if user not found', async () => {
            usersRepo.findOne.mockResolvedValue(null);

            await expect(
                service.validateLogin('nonexistent@example.com', undefined, 'password123'),
            ).rejects.toThrow(UnauthorizedException);
        });

        it('should throw ForbiddenException if user is suspended', async () => {
            usersRepo.findOne.mockResolvedValue({
                ...mockUser,
                isSuspended: true,
                suspensionReason: 'Violated terms',
            });

            await expect(
                service.validateLogin('test@example.com', undefined, 'password123'),
            ).rejects.toThrow(ForbiddenException);
        });

        it('should throw ForbiddenException for unverified driver', async () => {
            usersRepo.findOne.mockResolvedValue(mockDriverUser);
            profilesRepo.findOne.mockResolvedValue({ status: DriverStatus.PENDING_VERIFICATION });

            await expect(
                service.validateLogin(mockDriverUser.email!, undefined, 'password123'),
            ).rejects.toThrow(ForbiddenException);
        });

        it('should throw UnauthorizedException if password is wrong', async () => {
            usersRepo.findOne.mockResolvedValue(mockUser);
            (bcrypt.compare as jest.Mock).mockResolvedValue(false);

            await expect(
                service.validateLogin('test@example.com', undefined, 'wrongpassword'),
            ).rejects.toThrow(UnauthorizedException);
        });

        it('should return user on valid password login', async () => {
            usersRepo.findOne.mockResolvedValue(mockUser);
            (bcrypt.compare as jest.Mock).mockResolvedValue(true);

            const result = await service.validateLogin('test@example.com', undefined, 'correctpassword');

            expect(result).toEqual(mockUser);
            expect(bcrypt.compare).toHaveBeenCalledWith('correctpassword', 'hashed-password');
        });

        it('should return user on valid OTP login', async () => {
            usersRepo.findOne.mockResolvedValue(mockUser);
            usersRepo.save.mockResolvedValue(mockUser);
            otpService.verifyOtp.mockResolvedValue(true);

            const result = await service.validateLogin('test@example.com', undefined, undefined, '123456');

            expect(result).toEqual(mockUser);
            expect(otpService.verifyOtp).toHaveBeenCalledWith('test@example.com', '123456');
        });

        it('should throw UnauthorizedException for invalid OTP', async () => {
            usersRepo.findOne.mockResolvedValue(mockUser);
            otpService.verifyOtp.mockResolvedValue(false);

            await expect(
                service.validateLogin('test@example.com', undefined, undefined, '000000'),
            ).rejects.toThrow(UnauthorizedException);
        });
    });

    // ===============================
    // createSessionAndTokens
    // ===============================
    describe('createSessionAndTokens', () => {
        it('should create access and refresh tokens', async () => {
            (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-refresh-token');
            refreshRepo.create.mockReturnValue({ id: 'refresh-123' });
            refreshRepo.save.mockResolvedValue({
                id: 'refresh-123',
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            });

            const result = await service.createSessionAndTokens(
                mockUser as UserEntity,
                'Chrome/120',
                '192.168.1.1',
            );

            expect(result).toHaveProperty('accessToken');
            expect(result).toHaveProperty('refreshToken');
            expect(result).toHaveProperty('refreshTokenId');
            expect(jwtService.sign).toHaveBeenCalled();
            expect(refreshRepo.save).toHaveBeenCalled();
        });
    });

    // ===============================
    // rotateRefreshToken
    // ===============================
    describe('rotateRefreshToken', () => {
        const mockRefreshRecord = {
            id: 'refresh-123',
            userId: 'user-123',
            tokenHash: 'hashed-token',
            revokedAt: null,
            expiresAt: new Date(Date.now() + 100000),
        };

        it('should throw UnauthorizedException if token not found', async () => {
            refreshRepo.findOne.mockResolvedValue(null);

            await expect(
                service.rotateRefreshToken('token', 'invalid-id'),
            ).rejects.toThrow(UnauthorizedException);
        });

        it('should throw UnauthorizedException if token is revoked', async () => {
            refreshRepo.findOne.mockResolvedValue({
                ...mockRefreshRecord,
                revokedAt: new Date(),
            });

            await expect(
                service.rotateRefreshToken('token', 'refresh-123'),
            ).rejects.toThrow(UnauthorizedException);
        });

        it('should throw UnauthorizedException if token is expired', async () => {
            refreshRepo.findOne.mockResolvedValue({
                ...mockRefreshRecord,
                expiresAt: new Date(Date.now() - 100000),
            });
            refreshRepo.delete.mockResolvedValue({});

            await expect(
                service.rotateRefreshToken('token', 'refresh-123'),
            ).rejects.toThrow(UnauthorizedException);
        });

        it('should revoke all sessions on token mismatch (potential theft)', async () => {
            refreshRepo.findOne.mockResolvedValue(mockRefreshRecord);
            (bcrypt.compare as jest.Mock).mockResolvedValue(false);
            refreshRepo.update.mockResolvedValue({});

            await expect(
                service.rotateRefreshToken('wrong-token', 'refresh-123'),
            ).rejects.toThrow(UnauthorizedException);

            expect(refreshRepo.update).toHaveBeenCalledWith(
                { userId: 'user-123' },
                expect.objectContaining({ revokedAt: expect.any(Date) }),
            );
        });
    });

    // ===============================
    // revokeRefreshTokenById
    // ===============================
    describe('revokeRefreshTokenById', () => {
        it('should return false if token not found', async () => {
            refreshRepo.findOne.mockResolvedValue(null);

            const result = await service.revokeRefreshTokenById('invalid-id');

            expect(result).toBe(false);
        });

        it('should throw UnauthorizedException if userId does not match', async () => {
            refreshRepo.findOne.mockResolvedValue({ id: 'token-123', userId: 'user-123' });

            await expect(
                service.revokeRefreshTokenById('token-123', 'different-user'),
            ).rejects.toThrow(UnauthorizedException);
        });

        it('should revoke token successfully', async () => {
            const mockToken = { id: 'token-123', userId: 'user-123', revokedAt: null };
            refreshRepo.findOne.mockResolvedValue(mockToken);
            refreshRepo.save.mockResolvedValue({});

            const result = await service.revokeRefreshTokenById('token-123', 'user-123');

            expect(result).toBe(true);
            expect(refreshRepo.save).toHaveBeenCalled();
        });
    });

    // ===============================
    // getMe
    // ===============================
    describe('getMe', () => {
        it('should throw UnauthorizedException if user not found', async () => {
            usersRepo.findOne.mockResolvedValue(null);

            await expect(service.getMe('invalid-id')).rejects.toThrow(UnauthorizedException);
        });

        it('should return user profile', async () => {
            usersRepo.findOne.mockResolvedValue(mockUser);

            const result = await service.getMe('user-123');

            expect(result).toHaveProperty('id', 'user-123');
            expect(result).toHaveProperty('email', 'test@example.com');
            expect(result).toHaveProperty('role', UserRole.RIDER);
        });
    });

    // ===============================
    // validateJwtPayload
    // ===============================
    describe('validateJwtPayload', () => {
        it('should return null for invalid payload', async () => {
            const result = await service.validateJwtPayload(null as any);
            expect(result).toBeNull();
        });

        it('should return null if user not found', async () => {
            usersRepo.findOne.mockResolvedValue(null);

            const result = await service.validateJwtPayload({ sub: 'invalid-id', role: 'RIDER' });

            expect(result).toBeNull();
        });

        it('should return null if user is suspended', async () => {
            usersRepo.findOne.mockResolvedValue({ ...mockUser, isSuspended: true });

            const result = await service.validateJwtPayload({ sub: 'user-123', role: 'RIDER' });

            expect(result).toBeNull();
        });

        it('should return user for valid payload', async () => {
            usersRepo.findOne.mockResolvedValue(mockUser);

            const result = await service.validateJwtPayload({ sub: 'user-123', role: 'RIDER' });

            expect(result).toEqual(mockUser);
        });
    });
});
