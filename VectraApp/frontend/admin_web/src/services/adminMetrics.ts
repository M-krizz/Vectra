import { authHeadersOrThrow } from './adminSession';

export interface DemandPoint {
    time: string;
    trips: number;
}

export interface AdminMetricsOverview {
    activeDrivers: number;
    openSosAlerts: number;
    demandIndex: number;
    avgWaitMinutes: number;
    demandHistory: DemandPoint[];
}

const API_URL = (import.meta as any).env.VITE_API_URL ?? 'http://localhost:3000';

export async function fetchAdminMetricsOverview(): Promise<AdminMetricsOverview> {
    const response = await fetch(`${API_URL}/api/v1/admin/metrics/overview`, {
        headers: authHeadersOrThrow(),
    });

    if (!response.ok) {
        throw new Error(`Metrics request failed with status ${response.status}`);
    }

    return response.json();
}
