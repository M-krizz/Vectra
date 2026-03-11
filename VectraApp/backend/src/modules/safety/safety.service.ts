import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IncidentEntity } from './entities/incident.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { IncidentStatus, IncidentSeverity } from './types/incident.types';
import { UsersService } from '../Authentication/users/users.service';
import { LocationGateway } from '../location/location.gateway';
import { EmergencyContactEntity } from './entities/emergency-contact.entity';

@Injectable()
export class SafetyService {
  private readonly logger = new Logger(SafetyService.name);

  constructor(
    @InjectRepository(IncidentEntity)
    private incidentRepo: Repository<IncidentEntity>,
    @InjectRepository(EmergencyContactEntity)
    private contactRepo: Repository<EmergencyContactEntity>,
    @InjectRepository(RideRequestEntity)
    private rideRequestRepo: Repository<RideRequestEntity>,
    private usersService: UsersService,
    private locationGateway: LocationGateway,
  ) { }

  /**
   * Report a standard incident (Module 1.10)
   */
  async reportIncident(
    userId: string,
    description: string,
    rideId?: string,
  ): Promise<IncidentEntity> {
    const reportedBy = await this.usersService.findById(userId);
    if (!reportedBy) {
      throw new NotFoundException('User not found');
    }

    let ride: RideRequestEntity | null = null;
    if (rideId) {
      ride = await this.rideRequestRepo.findOne({ where: { id: rideId } });
      if (!ride) {
        throw new NotFoundException('Ride request not found');
      }
    }

    const incident = this.incidentRepo.create({
      reportedBy,
      description,
      ride,
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

    const saved = await this.incidentRepo.save(incident);

    this.locationGateway.server.to('admin:fleet').emit('incident_updated', {
      incidentId: saved.id,
      status: saved.status,
      severity: saved.severity,
      updatedAt: saved.updatedAt?.toISOString() ?? new Date().toISOString(),
    });

    return saved;
  }

  async escalateIncident(id: string): Promise<IncidentEntity> {
    const incident = await this.incidentRepo.findOne({ where: { id } });
    if (!incident) throw new NotFoundException('Incident not found');

    if (incident.status === IncidentStatus.RESOLVED) {
      return incident;
    }

    incident.status = IncidentStatus.INVESTIGATING;

    const saved = await this.incidentRepo.save(incident);

    this.locationGateway.server.to('admin:fleet').emit('incident_updated', {
      incidentId: saved.id,
      status: saved.status,
      severity: saved.severity,
      updatedAt: saved.updatedAt?.toISOString() ?? new Date().toISOString(),
    });

    return saved;
  }

  async getIncident(id: string): Promise<IncidentEntity | null> {
    return this.incidentRepo.findOne({
      where: { id },
      relations: ['reportedBy', 'ride'],
    });
  }

  // ===== Emergency Contacts =====

  async getContacts(userId: string): Promise<EmergencyContactEntity[]> {
    return this.contactRepo.find({ where: { userId } });
  }

  async addContact(userId: string, data: Partial<EmergencyContactEntity>): Promise<EmergencyContactEntity> {
    const contact = this.contactRepo.create({ ...data, userId });
    return this.contactRepo.save(contact);
  }

  async deleteContact(id: string, userId: string): Promise<void> {
    await this.contactRepo.delete({ id, userId });
  }
}
