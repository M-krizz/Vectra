import { get } from './api';

export interface Trip {
    id: string;
    driverUserId: string | null;
    status: string;
    assignedAt: string | null;
    startAt: string | null;
    endAt: string | null;
    createdAt: string;
    updatedAt: string;
}

export function getTrip(id: string): Promise<Trip> {
    return get<Trip>(`/api/v1/trips/${id}`);
}
