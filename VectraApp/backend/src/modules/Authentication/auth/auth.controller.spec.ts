import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { UserRole } from '../users/user.entity';

describe('AuthController', () => {
    let controller: AuthController;
    let authService: any;

    const mockUser = {
        id: 'user-123',
        email: 'test@example.com',
        phone: '+919876543210',
        role: UserRole.RIDER,
        fullName: 'Test User',
    };

    const mockTokens = {
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        refreshTokenId: 'refresh-123',
        accessExpiresIn: '15m',
        refreshExpiresAt: new Date(),
    };

    beforeEach(async () => {
        jest.clearAllMocks();

        const module: TestingModule = await Test.createTestingModule({
            controllers: [AuthController],
            providers: [
                {
                    provide: AuthService,
                    useValue: {
                        requestOtp: jest.fn(),
                        verifyOtpAndLogin: jest.fn(),
                        validateLogin: jest.fn(),
                        createSessionAndTokens: jest.fn(),
                        rotateRefreshToken: jest.fn(),
                        revokeRefreshTokenById: jest.fn(),
                        revokeAllForUser: jest.fn(),
                        listSessions: jest.fn(),
                        getMe: jest.fn(),
                    },
                },
            ],
        })
            .overrideGuard(JwtAuthGuard)
            .useValue({ canActivate: () => true })
            .compile();

        controller = module.get<AuthController>(AuthController);
        authService = module.get(AuthService);
    });

    it('should be defined', () => {
        expect(controller).toBeDefined();
    });

    // ===============================
    // POST /api/v1/auth/request-otp
    // ===============================
    describe('requestOtp', () => {
        it('should request OTP via phone', async () => {
            const expectedResult = { success: true, channel: 'phone', identifier: '+919876543210' };
            authService.requestOtp.mockResolvedValue(expectedResult);

            const result = await controller.requestOtp({
                channel: 'phone',
                identifier: '+919876543210',
            });

            expect(authService.requestOtp).toHaveBeenCalledWith('phone', '+919876543210');
            expect(result).toEqual(expectedResult);
        });

        it('should request OTP via email', async () => {
            const expectedResult = { success: true, channel: 'email', identifier: 'test@example.com' };
            authService.requestOtp.mockResolvedValue(expectedResult);

            const result = await controller.requestOtp({
                channel: 'email',
                identifier: 'test@example.com',
            });

            expect(authService.requestOtp).toHaveBeenCalledWith('email', 'test@example.com');
            expect(result).toEqual(expectedResult);
        });
    });

    // ===============================
    // POST /api/v1/auth/verify-otp
    // ===============================
    describe('verifyOtp', () => {
        it('should verify OTP and return user with tokens', async () => {
            const expectedResult = { user: mockUser, ...mockTokens };
            authService.verifyOtpAndLogin.mockResolvedValue(expectedResult);

            const result = await controller.verifyOtp(
                { identifier: '+919876543210', code: '123456' },
                '192.168.1.1',
                'Chrome/120',
            );

            expect(authService.verifyOtpAndLogin).toHaveBeenCalledWith(
                '+919876543210',
                '123456',
                undefined,
                'Chrome/120',
                '192.168.1.1',
            );
            expect(result).toEqual(expectedResult);
        });
    });

    // ===============================
    // POST /api/v1/auth/login
    // ===============================
    describe('login', () => {
        it('should login with email and password', async () => {
            authService.validateLogin.mockResolvedValue(mockUser);
            authService.createSessionAndTokens.mockResolvedValue(mockTokens);

            const result = await controller.login(
                { email: 'test@example.com', password: 'password123' },
                '192.168.1.1',
                'Chrome/120',
            );

            expect(authService.validateLogin).toHaveBeenCalledWith(
                'test@example.com',
                undefined,
                'password123',
                undefined,
            );
            expect(authService.createSessionAndTokens).toHaveBeenCalledWith(
                mockUser,
                'Chrome/120',
                '192.168.1.1',
            );
            expect(result).toEqual(mockTokens);
        });

        it('should login with phone and OTP', async () => {
            authService.validateLogin.mockResolvedValue(mockUser);
            authService.createSessionAndTokens.mockResolvedValue(mockTokens);

            const result = await controller.login(
                { phone: '+919876543210', otp: '123456' },
                '192.168.1.1',
                'Safari/17',
            );

            expect(authService.validateLogin).toHaveBeenCalledWith(
                undefined,
                '+919876543210',
                undefined,
                '123456',
            );
            expect(result).toEqual(mockTokens);
        });
    });

    // ===============================
    // POST /api/v1/auth/refresh
    // ===============================
    describe('refresh', () => {
        it('should rotate refresh token', async () => {
            const newTokens = { ...mockTokens, accessToken: 'new-access-token' };
            authService.rotateRefreshToken.mockResolvedValue(newTokens);

            const result = await controller.refresh(
                { refreshToken: 'old-refresh-token' },
                '192.168.1.1',
                'Chrome/120',
                'refresh-123',
            );

            expect(authService.rotateRefreshToken).toHaveBeenCalledWith(
                'old-refresh-token',
                'refresh-123',
                'Chrome/120',
                '192.168.1.1',
            );
            expect(result).toEqual(newTokens);
        });
    });

    // ===============================
    // POST /api/v1/auth/logout
    // ===============================
    describe('logout', () => {
        it('should revoke specific refresh token', async () => {
            authService.revokeRefreshTokenById.mockResolvedValue(true);

            const result = await controller.logout('refresh-123', { user: { userId: 'user-123' } });

            expect(authService.revokeRefreshTokenById).toHaveBeenCalledWith('refresh-123', 'user-123');
            expect(result).toBe(true);
        });
    });

    // ===============================
    // POST /api/v1/auth/logout-all
    // ===============================
    describe('logoutAll', () => {
        it('should revoke all sessions for user', async () => {
            authService.revokeAllForUser.mockResolvedValue(true);

            const result = await controller.logoutAll({ user: { userId: 'user-123' } });

            expect(authService.revokeAllForUser).toHaveBeenCalledWith('user-123');
            expect(result).toBe(true);
        });
    });

    // ===============================
    // GET /api/v1/auth/sessions
    // ===============================
    describe('listSessions', () => {
        it('should list active sessions for user', async () => {
            const sessions = [
                { id: 'session-1', deviceInfo: 'Chrome', ip: '192.168.1.1' },
                { id: 'session-2', deviceInfo: 'Safari', ip: '192.168.1.2' },
            ];
            authService.listSessions.mockResolvedValue(sessions);

            const result = await controller.listSessions({ user: { userId: 'user-123' } });

            expect(authService.listSessions).toHaveBeenCalledWith('user-123');
            expect(result).toEqual(sessions);
        });
    });

    // ===============================
    // GET /api/v1/auth/me
    // ===============================
    describe('me', () => {
        it('should return current user profile', async () => {
            authService.getMe.mockResolvedValue(mockUser);

            const result = await controller.me({ user: { userId: 'user-123' } });

            expect(authService.getMe).toHaveBeenCalledWith('user-123');
            expect(result).toEqual(mockUser);
        });
    });
});
