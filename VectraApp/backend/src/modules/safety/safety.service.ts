import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IncidentEntity } from './entities/incident.entity';
import { UserEntity } from '../Authentication/users/user.entity';
import { RideRequestEntity } from '../ride_requests/ride-request.entity';
import { IncidentStatus } from './types/incident.types';
import { UsersService } from '../Authentication/users/users.service';

@Injectable()
export class SafetyService {
  constructor(
    @InjectRepository(IncidentEntity)
    private incidentRepo: Repository<IncidentEntity>,
    private usersService: UsersService,
  ) {}

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
    });
    return this.incidentRepo.save(incident);
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