import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { SafetyService } from './safety.service';
import { IncidentEntity } from './entities/incident.entity';
import { UsersService } from '../Authentication/users/users.service';
import { IncidentStatus, IncidentSeverity } from './types/incident.types';
import { UserEntity, UserRole } from '../Authentication/users/user.entity';

// ── Helpers ────────────────────────────────────────────────────────────────

const makeUser = (overrides: Partial<UserEntity> = {}): UserEntity =>
  ({
    id:       'user-uuid-1',
    role:     UserRole.RIDER,
    email:    'test@example.com',
    fullName: 'Test User',
    ...overrides,
  } as UserEntity);

const makeIncident = (overrides: Partial<IncidentEntity> = {}): IncidentEntity =>
  ({
    id:           'inc-uuid-1',
    description:  'Driver was reckless',
    status:       IncidentStatus.OPEN,
    severity:     IncidentSeverity.MEDIUM,
    resolution:   null,
    resolvedById: null,
    resolvedAt:   null,
    reportedBy:   makeUser(),
    ride:         null,
    createdAt:    new Date('2024-06-01T10:00:00Z'),
    updatedAt:    new Date('2024-06-01T10:00:00Z'),
    ...overrides,
  } as IncidentEntity);

const makeIncidentRepo = () => ({
  findOne: jest.fn(),
  find:    jest.fn(),
  create:  jest.fn(),
  save:    jest.fn(),
});

// ── Tests ──────────────────────────────────────────────────────────────────

describe('SafetyService', () => {
  let service: SafetyService;
  let incidentRepo: ReturnType<typeof makeIncidentRepo>;
  let usersService: jest.Mocked<Pick<UsersService, 'findById'>>;

  beforeEach(async () => {
    incidentRepo = makeIncidentRepo();
    usersService = { findById: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SafetyService,
        { provide: getRepositoryToken(IncidentEntity), useValue: incidentRepo },
        { provide: UsersService, useValue: usersService },
      ],
    }).compile();

    service = module.get<SafetyService>(SafetyService);
  });

  afterEach(() => jest.clearAllMocks());

  // ── reportIncident ───────────────────────────────────────────────────────

  describe('reportIncident', () => {
    it('throws NotFoundException when the reporting user does not exist', async () => {
      usersService.findById.mockResolvedValue(null);

      await expect(
        service.reportIncident('ghost-uuid', 'Some issue'),
      ).rejects.toThrow(NotFoundException);
    });

    it('creates and saves an incident with the correct description', async () => {
      const user     = makeUser();
      const incident = makeIncident();
      usersService.findById.mockResolvedValue(user);
      incidentRepo.create.mockReturnValue(incident);
      incidentRepo.save.mockResolvedValue(incident);

      const result = await service.reportIncident('user-uuid-1', 'Driver was reckless');

      expect(incidentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          reportedBy:  user,
          description: 'Driver was reckless',
        }),
      );
      expect(result.description).toBe('Driver was reckless');
    });

    it('associates a ride when one is provided', async () => {
      const user     = makeUser();
      const ride     = { id: 'ride-uuid-1' } as any;
      const incident = makeIncident({ ride });
      usersService.findById.mockResolvedValue(user);
      incidentRepo.create.mockReturnValue(incident);
      incidentRepo.save.mockResolvedValue(incident);

      const result = await service.reportIncident('user-uuid-1', 'Unsafe driving', ride);
      expect(incidentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ ride }),
      );
      expect(result.ride).toBe(ride);
    });

    it('sets ride to null when no ride is provided', async () => {
      const user     = makeUser();
      const incident = makeIncident({ ride: null });
      usersService.findById.mockResolvedValue(user);
      incidentRepo.create.mockReturnValue(incident);
      incidentRepo.save.mockResolvedValue(incident);

      await service.reportIncident('user-uuid-1', 'General concern');
      expect(incidentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({ ride: null }),
      );
    });
  });

  // ── listIncidents ────────────────────────────────────────────────────────

  describe('listIncidents', () => {
    it('returns incidents ordered by createdAt DESC with relations', async () => {
      const incidents = [makeIncident(), makeIncident({ id: 'inc-uuid-2' })];
      incidentRepo.find.mockResolvedValue(incidents);

      const result = await service.listIncidents();

      expect(incidentRepo.find).toHaveBeenCalledWith({
        relations: ['reportedBy', 'ride'],
        order:     { createdAt: 'DESC' },
      });
      expect(result).toHaveLength(2);
    });

    it('returns empty array when there are no incidents', async () => {
      incidentRepo.find.mockResolvedValue([]);
      const result = await service.listIncidents();
      expect(result).toEqual([]);
    });
  });

  // ── resolveIncident ──────────────────────────────────────────────────────

  describe('resolveIncident', () => {
    it('throws NotFoundException when incident does not exist', async () => {
      incidentRepo.findOne.mockResolvedValue(null);

      await expect(
        service.resolveIncident('ghost-uuid', 'Spoke to driver', 'admin-uuid'),
      ).rejects.toThrow(NotFoundException);
    });

    it('sets status to RESOLVED with resolution text, resolvedById, and resolvedAt', async () => {
      const incident = makeIncident();
      incidentRepo.findOne.mockResolvedValue(incident);
      incidentRepo.save.mockImplementation((inc) => Promise.resolve(inc));

      const result = await service.resolveIncident('inc-uuid-1', 'Spoke to driver', 'admin-uuid');

      expect(result.status).toBe(IncidentStatus.RESOLVED);
      expect(result.resolution).toBe('Spoke to driver');
      expect(result.resolvedById).toBe('admin-uuid');
      expect(result.resolvedAt).toBeInstanceOf(Date);
    });

    it('persists the resolved state by calling save', async () => {
      const incident = makeIncident();
      incidentRepo.findOne.mockResolvedValue(incident);
      incidentRepo.save.mockImplementation((inc) => Promise.resolve(inc));

      await service.resolveIncident('inc-uuid-1', 'Resolved', 'admin-uuid');
      expect(incidentRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: IncidentStatus.RESOLVED }),
      );
    });
  });

  // ── getIncident ──────────────────────────────────────────────────────────

  describe('getIncident', () => {
    it('returns the incident with relations when found', async () => {
      incidentRepo.findOne.mockResolvedValue(makeIncident());

      const result = await service.getIncident('inc-uuid-1');

      expect(incidentRepo.findOne).toHaveBeenCalledWith({
        where:     { id: 'inc-uuid-1' },
        relations: ['reportedBy', 'ride'],
      });
      expect(result?.id).toBe('inc-uuid-1');
    });

    it('returns null when incident is not found', async () => {
      incidentRepo.findOne.mockResolvedValue(null);
      const result = await service.getIncident('ghost-uuid');
      expect(result).toBeNull();
    });
  });
});
