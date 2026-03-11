import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { SafetyController } from '../src/modules/safety/safety.controller';
import { SafetyService } from '../src/modules/safety/safety.service';
import { IncidentEntity } from '../src/modules/safety/entities/incident.entity';
import { UsersService } from '../src/modules/Authentication/users/users.service';
import { JwtAuthGuard } from '../src/modules/Authentication/auth/jwt-auth.guard';
import { PermissionsGuard } from '../src/modules/Authentication/common/permissions.guard';
import { Reflector } from '@nestjs/core';
import { IncidentStatus } from '../src/modules/safety/types/incident.types';
import { RbacService } from '../src/modules/Authentication/rbac/rbac.service';

describe('Safety Integration (Controller -> Service -> Repo)', () => {
  let controller: SafetyController;
  let service: SafetyService;
  let incidentRepo: any;
  let usersService: any;

  // Mock Request Object
  const mockReq = {
    user: { userId: 'user-uuid', role: 'RIDER', isVerified: true },
  };

  // Mock DB Repositories & Services
  const mockIncidentRepo = {
    create: jest.fn().mockImplementation((dto) => dto),
    save: jest.fn().mockImplementation((incident) => Promise.resolve({ id: 'inc-123', ...incident, createdAt: new Date() })),
    find: jest.fn(),
    findOne: jest.fn(),
  };

  const mockUsersService = {
    findById: jest.fn().mockResolvedValue({ id: 'user-uuid', fullName: 'Test User' }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SafetyController],
      providers: [
        SafetyService,
        { provide: getRepositoryToken(IncidentEntity), useValue: mockIncidentRepo },
        { provide: UsersService, useValue: mockUsersService },
        // Mock Guards so we can test the integration without JWT logic
        { provide: JwtAuthGuard, useValue: { canActivate: jest.fn(() => true) } },
        { provide: PermissionsGuard, useValue: { canActivate: jest.fn(() => true) } },
        { provide: RbacService, useValue: { hasPermission: jest.fn(() => true) } },
        Reflector,
      ],
    }).compile();

    controller = module.get<SafetyController>(SafetyController);
    service = module.get<SafetyService>(SafetyService);
    incidentRepo = module.get(getRepositoryToken(IncidentEntity));
    usersService = module.get(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('Report Incident Flow', () => {
    it('INT-SAFE-001: Controller passes body to Service -> creates and saves Incident via Repo', async () => {
      const dto = { description: 'Driver was speeding' };
      
      const result = await controller.reportIncident(mockReq as any, dto);

      // Verify Service Interaction
      expect(usersService.findById).toHaveBeenCalledWith('user-uuid');
      
      // Verify Repo Interaction
      expect(incidentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          description: 'Driver was speeding',
          reportedBy: expect.objectContaining({ id: 'user-uuid' }),
        })
      );
      expect(incidentRepo.save).toHaveBeenCalled();
      
      // Verify Response
      expect(result.id).toEqual('inc-123');
      expect(result.description).toEqual('Driver was speeding');
    });

    it('INT-SAFE-002: Service throws NotFound if reporting user does not exist', async () => {
      mockUsersService.findById.mockResolvedValueOnce(null); // User not found
      
      const dto = { description: 'Something bad' };
      
      await expect(controller.reportIncident(mockReq as any, dto)).rejects.toThrow('User not found');
      expect(incidentRepo.save).not.toHaveBeenCalled();
    });
  });

  describe('Resolve Incident Flow', () => {
    it('INT-SAFE-003: Controller passes resolution -> Service updates status to RESOLVED -> saves', async () => {
      const existingIncident = { id: 'inc-123', status: IncidentStatus.OPEN, description: 'Speeding' };
      mockIncidentRepo.findOne.mockResolvedValueOnce(existingIncident);
      mockIncidentRepo.save.mockResolvedValueOnce({ 
        ...existingIncident, 
        status: IncidentStatus.RESOLVED, 
        resolution: 'Warning issued',
        resolvedById: 'admin-uuid'
      });

      // Admin resolves the incident
      const adminReq = { user: { userId: 'admin-uuid', role: 'ADMIN' } };
      const dto = { resolution: 'Warning issued' };
      
      const result = await controller.resolveIncident(adminReq as any, 'inc-123', dto);

      expect(incidentRepo.findOne).toHaveBeenCalledWith({ where: { id: 'inc-123' }});
      expect(incidentRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({
          status: IncidentStatus.RESOLVED,
          resolution: 'Warning issued',
          resolvedById: 'admin-uuid'
        })
      );
      expect(result.status).toEqual(IncidentStatus.RESOLVED);
    });

    it('INT-SAFE-004: Resolving non-existent incident throws NotFound', async () => {
      mockIncidentRepo.findOne.mockResolvedValueOnce(null);
      
      await expect(
        controller.resolveIncident(mockReq as any, 'ghost-id', { resolution: 'fixed' })
      ).rejects.toThrow('Incident not found');
      
      expect(incidentRepo.save).not.toHaveBeenCalled();
    });
  });
});
