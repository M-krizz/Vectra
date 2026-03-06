import { get, patch } from './api';

export interface Incident {
    id: string;
    reportedById: string;
    description: string;
    status: string;
    resolution: string | null;
    resolvedById: string | null;
    createdAt: string;
    updatedAt: string;
}

export function listIncidents(): Promise<Incident[]> {
    return get<Incident[]>('/api/v1/safety/incidents');
}

export function getIncident(id: string): Promise<Incident> {
    return get<Incident>(`/api/v1/safety/incidents/${id}`);
}

export function resolveIncident(id: string, resolution: string) {
    return patch(`/api/v1/safety/incidents/${id}/resolve`, { resolution });
}
