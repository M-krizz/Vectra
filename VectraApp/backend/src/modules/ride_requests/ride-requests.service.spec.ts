import { Test, TestingModule } from '@nestjs/testing';
import { RideRequestsService } from './ride-requests.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { RideRequestEntity, RideRequestStatus, RideType } from './ride-request.entity';
import { Repository } from 'typeorm';
import { CreateRideRequestDto } from './dto/create-ride-request.dto';

describe('RideRequestsService', () => {
    let service: RideRequestsService;
    let repo: Repository<RideRequestEntity>;

    const mockRideRequest = {
        id: 'req_123',
        riderUserId: 'user_123',
        pickupPoint: { type: 'Point', coordinates: [0, 0] },
        dropPoint: { type: 'Point', coordinates: [1, 1] },
        status: RideRequestStatus.REQUESTED,
    };

    const mockRepo = {
        create: jest.fn().mockImplementation((dto) => dto),
        save: jest.fn().mockResolvedValue(mockRideRequest),
        findOne: jest.fn().mockResolvedValue(mockRideRequest),
        update: jest.fn().mockResolvedValue({ affected: 1 }),
    };

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [
                RideRequestsService,
                {
                    provide: getRepositoryToken(RideRequestEntity),
                    useValue: mockRepo,
                },
            ],
        }).compile();

        service = module.get<RideRequestsService>(RideRequestsService);
        repo = module.get<Repository<RideRequestEntity>>(
            getRepositoryToken(RideRequestEntity),
        );
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    describe('createRequest', () => {
        it('should create and save a new ride request', async () => {
            const dto: CreateRideRequestDto = {
                pickupPoint: { type: 'Point', coordinates: [0, 0] },
                dropPoint: { type: 'Point', coordinates: [1, 1] },
                pickupAddress: 'A',
                dropAddress: 'B',
                rideType: RideType.SOLO,
            };

            const result = await service.createRequest('user_123', dto);

            expect(repo.create).toHaveBeenCalledWith(expect.objectContaining({
                riderUserId: 'user_123',
                status: RideRequestStatus.REQUESTED,
            }));
            expect(repo.save).toHaveBeenCalled();
            expect(result).toEqual(mockRideRequest);
        });
    });

    describe('getRequest', () => {
        it('should retrieve a request by ID', async () => {
            const result = await service.getRequest('req_123');
            expect(repo.findOne).toHaveBeenCalledWith({ where: { id: 'req_123' } });
            expect(result).toEqual(mockRideRequest);
        });
    });

    describe('getActiveRequestForUser', () => {
        it('should return the latest ACTIVE request', async () => {
            const result = await service.getActiveRequestForUser('user_123');
            expect(repo.findOne).toHaveBeenCalledWith({
                where: { riderUserId: 'user_123', status: RideRequestStatus.REQUESTED },
                order: { requestedAt: 'DESC' },
            });
            expect(result).toEqual(mockRideRequest);
        });
    });

    describe('cancelRequest', () => {
        it('should update status to CANCELLED', async () => {
            await service.cancelRequest('req_123', 'user_123');
            expect(repo.update).toHaveBeenCalledWith(
                { id: 'req_123', riderUserId: 'user_123' },
                { status: RideRequestStatus.CANCELLED },
            );
        });
    });
});
