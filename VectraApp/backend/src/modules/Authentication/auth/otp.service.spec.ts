import { Test, TestingModule } from '@nestjs/testing';
import { HttpException, HttpStatus } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { OtpService } from './otp.service';
import { REDIS } from '../../../integrations/redis/redis.module';

// Mock bcrypt
jest.mock('bcrypt', () => ({
    compare: jest.fn(),
    hash: jest.fn(),
}));

describe('OtpService', () => {
    let service: OtpService;
    let redis: any;

    beforeEach(async () => {
        jest.clearAllMocks();

        // Set up environment variables
        process.env.OTP_TTL_SECONDS = '300';
        process.env.OTP_REQUEST_COOLDOWN_SECONDS = '30';
        process.env.OTP_MAX_VERIFY_ATTEMPTS = '5';
        process.env.NODE_ENV = 'development';

        const module: TestingModule = await Test.createTestingModule({
            providers: [
                OtpService,
                {
                    provide: REDIS,
                    useValue: {
                        get: jest.fn(),
                        set: jest.fn(),
                        del: jest.fn(),
                        incr: jest.fn(),
                        expire: jest.fn(),
                    },
                },
            ],
        }).compile();

        service = module.get<OtpService>(OtpService);
        redis = module.get(REDIS);
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    // ===============================
    // requestOtp
    // ===============================
    describe('requestOtp', () => {
        it('should throw TOO_MANY_REQUESTS if cooldown is active', async () => {
            redis.get.mockResolvedValue('1'); // Cooldown exists

            await expect(
                service.requestOtp('phone', '+919876543210'),
            ).rejects.toThrow(HttpException);

            try {
                await service.requestOtp('phone', '+919876543210');
            } catch (e: any) {
                expect(e.getStatus()).toBe(HttpStatus.TOO_MANY_REQUESTS);
            }
        });

        it('should generate 6-digit OTP and store hashed version', async () => {
            redis.get.mockResolvedValue(null); // No cooldown
            (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-otp');
            redis.set.mockResolvedValue('OK');
            redis.del.mockResolvedValue(1);

            const result = await service.requestOtp('phone', '+919876543210');

            expect(result.success).toBe(true);
            expect(result.channel).toBe('phone');
            expect(result.identifier).toBe('+919876543210');
            expect(result.expiresInSeconds).toBe(300);

            // In dev mode, OTP should be returned
            expect(result.devOtp).toBeDefined();
            expect(result.devOtp).toMatch(/^\d{6}$/); // 6 digits

            // Verify bcrypt.hash was called
            expect(bcrypt.hash).toHaveBeenCalled();

            // Verify Redis operations
            expect(redis.set).toHaveBeenCalled();
            expect(redis.del).toHaveBeenCalled();
        });

        it('should generate OTP for email channel', async () => {
            redis.get.mockResolvedValue(null);
            (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-otp');
            redis.set.mockResolvedValue('OK');
            redis.del.mockResolvedValue(1);

            const result = await service.requestOtp('email', 'test@example.com');

            expect(result.success).toBe(true);
            expect(result.channel).toBe('email');
            expect(result.identifier).toBe('test@example.com');
        });

        it('should set cooldown after generating OTP', async () => {
            redis.get.mockResolvedValue(null);
            (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-otp');
            redis.set.mockResolvedValue('OK');
            redis.del.mockResolvedValue(1);

            await service.requestOtp('phone', '+919876543210');

            // Verify cooldown was set (second call to redis.set)
            expect(redis.set).toHaveBeenCalledTimes(2);
            const cooldownCall = redis.set.mock.calls[1];
            expect(cooldownCall[0]).toBe('otp_cooldown:+919876543210');
        });
    });

    // ===============================
    // verifyOtp
    // ===============================
    describe('verifyOtp', () => {
        it('should return false if no OTP hash exists', async () => {
            redis.get.mockResolvedValue(null);

            const result = await service.verifyOtp('+919876543210', '123456');

            expect(result).toBe(false);
        });

        it('should throw TOO_MANY_REQUESTS if max attempts exceeded', async () => {
            redis.get
                .mockResolvedValueOnce('hashed-otp') // OTP hash exists
                .mockResolvedValueOnce('5'); // 5 attempts (max reached)

            await expect(
                service.verifyOtp('+919876543210', '123456'),
            ).rejects.toThrow(HttpException);
        });

        it('should return false and increment attempts on wrong OTP', async () => {
            redis.get
                .mockResolvedValueOnce('hashed-otp')
                .mockResolvedValueOnce('2'); // 2 attempts
            (bcrypt.compare as jest.Mock).mockResolvedValue(false);
            redis.incr.mockResolvedValue(3);
            redis.expire.mockResolvedValue(1);

            const result = await service.verifyOtp('+919876543210', '000000');

            expect(result).toBe(false);
            expect(redis.incr).toHaveBeenCalledWith('otp_attempts:+919876543210');
            expect(redis.expire).toHaveBeenCalled();
        });

        it('should return true and delete OTP on correct verification', async () => {
            redis.get
                .mockResolvedValueOnce('hashed-otp')
                .mockResolvedValueOnce('0'); // 0 attempts
            (bcrypt.compare as jest.Mock).mockResolvedValue(true);
            redis.del.mockResolvedValue(1);

            const result = await service.verifyOtp('+919876543210', '123456');

            expect(result).toBe(true);
            expect(redis.del).toHaveBeenCalledWith('otp:+919876543210');
            expect(redis.del).toHaveBeenCalledWith('otp_attempts:+919876543210');
        });

        it('should handle OTP verification for email identifier', async () => {
            redis.get
                .mockResolvedValueOnce('hashed-otp')
                .mockResolvedValueOnce('1');
            (bcrypt.compare as jest.Mock).mockResolvedValue(true);
            redis.del.mockResolvedValue(1);

            const result = await service.verifyOtp('test@example.com', '654321');

            expect(result).toBe(true);
            expect(bcrypt.compare).toHaveBeenCalledWith('654321', 'hashed-otp');
        });
    });
});
