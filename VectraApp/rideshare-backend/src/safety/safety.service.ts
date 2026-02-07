import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Incident, IncidentStatus } from './entities/incident.entity';
import { User } from '../users/user.entity';
import { RideRequest } from '../rides/entities/ride-request.entity';

@Injectable()
export class SafetyService {
    constructor(
        @InjectRepository(Incident)
        private incidentRepo: Repository<Incident>,
    ) { }

    async reportIncident(reportedBy: User, description: string, ride?: RideRequest) {
        const incident = this.incidentRepo.create({
            reportedBy,
            description,
            ride,
        });
        return this.incidentRepo.save(incident);
    }

    async listIncidents() {
        return this.incidentRepo.find({
            relations: ['reportedBy', 'ride'],
            order: { createdAt: 'DESC' },
        });
    }

    async resolveIncident(id: string, resolution: string) {
        const incident = await this.incidentRepo.findOne({ where: { id } });
        if (!incident) throw new NotFoundException('Incident not found');

        incident.status = IncidentStatus.RESOLVED;
        incident.resolution = resolution;
        return this.incidentRepo.save(incident);
    }
}
