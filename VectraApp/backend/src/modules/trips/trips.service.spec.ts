import { Test, TestingModule } from '@nestjs/testing';
import { TripsService } from './trips.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { TripEntity } from './trip.entity';
import { TripEventEntity } from './trip-event.entity';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';

describe('TripsService', () => {
    let service: TripsService;
    let tripRepo: Repository<TripEntity>;
    let eventRepo: Repository<TripEventEntity>;

    const mockTrip = {
        id: 'trip_123',
        status: 'IN_PROGRESS',
    };

    const mockLocationEvent = {
        tripId: 'trip_123',
        eventType: 'DRIVER_LOCATION',
        metadata: { lat: 10, lng: 20 },
    };

    const mockTripRepo = {
        findOne: jest.fn(),
    };

    const mockEventRepo = {
        findOne: jest.fn(),
        create: jest.fn().mockImplementation((dto) => dto),
        save: jest.fn().mockResolvedValue(mockLocationEvent),
    };

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
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
        }).compile();

        service = module.get<TripsService>(TripsService);
        tripRepo = module.get<Repository<TripEntity>>(getRepositoryToken(TripEntity));
        eventRepo = module.get<Repository<TripEventEntity>>(getRepositoryToken(TripEventEntity));
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    describe('getTrip', () => {
        it('should return trip details with latest driver location', async () => {
            mockTripRepo.findOne.mockResolvedValue(mockTrip);
            mockEventRepo.findOne.mockResolvedValue(mockLocationEvent);

            const result = await service.getTrip('trip_123');

            expect(tripRepo.findOne).toHaveBeenCalledWith({
                where: { id: 'trip_123' },
                relations: ['driver', 'tripRiders', 'tripRiders.rider'],
            });
            expect(eventRepo.findOne).toHaveBeenCalledWith({
                where: { tripId: 'trip_123', eventType: 'DRIVER_LOCATION' },
                order: { createdAt: 'DESC' },
            });
            expect(result).toEqual({ ...mockTrip, latestLocation: { lat: 10, lng: 20 } });
        });

        it('should return null location if no event found', async () => {
            mockTripRepo.findOne.mockResolvedValue(mockTrip);
            mockEventRepo.findOne.mockResolvedValue(null);

            const result = await service.getTrip('trip_123');
            expect(result).toEqual({ ...mockTrip, latestLocation: null });
        });

        it('should throw NotFoundException if trip does not exist', async () => {
            mockTripRepo.findOne.mockResolvedValue(null);

            await expect(service.getTrip('invalid_id')).rejects.toThrow(NotFoundException);
        });
    });

    describe('updateDriverLocation', () => {
        it('should save a new DRIVER_LOCATION event', async () => {
            await service.updateDriverLocation('trip_123', 12.34, 56.78);

            expect(eventRepo.create).toHaveBeenCalledWith({
                tripId: 'trip_123',
                eventType: 'DRIVER_LOCATION',
                metadata: { lat: 12.34, lng: 56.78 },
            });
            expect(eventRepo.save).toHaveBeenCalled();
        });
    });
});
