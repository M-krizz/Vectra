import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IncidentEntity } from './entities/incident.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { IncidentStatus, IncidentSeverity } from './types/incident.types';
import { UsersService } from '../Authentication/users/users.service';
import { LocationGateway } from '../location/location.gateway';

@Injectable()
export class SafetyService {
  private readonly logger = new Logger(SafetyService.name);

  constructor(
    @InjectRepository(IncidentEntity)
    private incidentRepo: Repository<IncidentEntity>,
    private usersService: UsersService,
    private locationGateway: LocationGateway,
  ) { }

  /**
   * Report a standard incident (Module 1.10)
   */
  async reportIncident(
    userId: string,
    description: string,
    ride?: RideRequestEntity,
  ): Promise<IncidentEntity> {
    const reportedBy = await this.usersService.findById(userId);
    if (!reportedBy) {
      throw new NotFoundException('User not found');
    }

    const incident = this.incidentRepo.create({
      reportedBy,
      description,
      ride: ride || null,
      severity: IncidentSeverity.MEDIUM,
    });
    return this.incidentRepo.save(incident);
  }

  /**
   * Trigger SOS - Escalates immediately to admins (Module 1.10)
   */
  async triggerSOS(userId: string, tripId?: string, location?: { lat: number, lng: number }): Promise<IncidentEntity> {
    const user = await this.usersService.findById(userId);
    if (!user) throw new NotFoundException('User not found');

    const incident = this.incidentRepo.create({
      reportedBy: user,
      description: `EMERGENCY: SOS triggered by ${user.fullName || user.phone || user.id}`,
      status: IncidentStatus.OPEN,
      severity: IncidentSeverity.HIGH,
    });

    const saved = await this.incidentRepo.save(incident);

    // Broadcast to Admin Fleet Room (Module 1.10)
    // Auth check on the other end will ensure only admins see this
    this.locationGateway.server.to('admin:fleet').emit('sos_alert', {
      incidentId: saved.id,
      userId,
      userName: user.fullName,
      userPhone: user.phone,
      tripId,
      location,
      timestamp: new Date().toISOString(),
    });

    this.logger.warn(`SOS Alert triggered by user ${userId}`);

    return saved;
  }

  async listIncidents(): Promise<IncidentEntity[]> {
    return this.incidentRepo.find({
      relations: ['reportedBy', 'ride'],
      order: { createdAt: 'DESC' },
    });
  }

  async resolveIncident(
    id: string,
    resolution: string,
    resolvedById: string,
  ): Promise<IncidentEntity> {
    const incident = await this.incidentRepo.findOne({ where: { id } });
    if (!incident) throw new NotFoundException('Incident not found');

    incident.status = IncidentStatus.RESOLVED;
    incident.resolution = resolution;
    incident.resolvedById = resolvedById;
    incident.resolvedAt = new Date();

    return this.incidentRepo.save(incident);
  }

  async getIncident(id: string): Promise<IncidentEntity | null> {
    return this.incidentRepo.findOne({
      where: { id },
      relations: ['reportedBy', 'ride'],
    });
  }
}
