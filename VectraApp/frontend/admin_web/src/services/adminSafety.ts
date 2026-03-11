import { authHeadersOrThrow } from './adminSession';

const API_URL = (import.meta as any).env.VITE_API_URL ?? 'http://localhost:3000';

export type IncidentStatus = 'OPEN' | 'INVESTIGATING' | 'RESOLVED' | 'DISMISSED';

export interface SafetyIncident {
    id: string;
    status: IncidentStatus;
    severity: string;
    description: string;
    resolution?: string | null;
    createdAt: string;
    updatedAt?: string;
    resolvedAt?: string | null;
    reportedBy?: {
        id: string;
        fullName?: string | null;
        phone?: string | null;
    };
    ride?: {
        id: string;
    } | null;
}

export async function fetchSafetyIncidents(): Promise<SafetyIncident[]> {
    const response = await fetch(`${API_URL}/api/v1/safety/incidents`, {
        headers: authHeadersOrThrow(),
    });

    if (!response.ok) {
        throw new Error(`Failed to load incidents (${response.status})`);
    }

    return response.json();
}

export async function resolveSafetyIncident(incidentId: string, resolution: string): Promise<SafetyIncident> {
    const response = await fetch(`${API_URL}/api/v1/safety/incidents/${incidentId}/resolve`, {
        method: 'PATCH',
        headers: authHeadersOrThrow(),
        body: JSON.stringify({ resolution }),
    });

    if (!response.ok) {
        throw new Error(`Failed to resolve incident (${response.status})`);
    }

    return response.json();
}

export async function escalateSafetyIncident(incidentId: string, note?: string): Promise<SafetyIncident> {
    const response = await fetch(`${API_URL}/api/v1/safety/incidents/${incidentId}/escalate`, {
        method: 'PATCH',
        headers: authHeadersOrThrow(),
        body: JSON.stringify({ note }),
    });

    if (!response.ok) {
        throw new Error(`Failed to escalate incident (${response.status})`);
    }

    return response.json();
}
