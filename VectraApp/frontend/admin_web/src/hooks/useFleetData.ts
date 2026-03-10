import { useState, useEffect, useCallback, useRef } from 'react';
import { connectFleetSocket } from '../services/fleetSocket';
import { fetchAdminMetricsOverview, type DemandPoint } from '../services/adminMetrics';
import { getAdminAccessToken } from '../services/adminSession';
import {
    escalateSafetyIncident,
    fetchSafetyIncidents,
    resolveSafetyIncident,
    type IncidentStatus,
    type SafetyIncident,
} from '../services/adminSafety';

export interface DriverPin {
    driverId: string;
    lat: number;
    lng: number;
    heading: number;
    speed: number;
    updatedAt: string;
}

export interface SosAlert {
    id: string;
    userId: string;
    userName?: string;
    tripId?: string;
    lat?: number;
    lng?: number;
    severity: string;
    status: IncidentStatus;
    description?: string;
    resolution?: string | null;
    timestamp: string;
}

export function useFleetData() {
    const [isConnected, setIsConnected] = useState(false);
    const [drivers, setDrivers] = useState<Map<string, DriverPin>>(new Map());
    const [alerts, setAlerts] = useState<SosAlert[]>([]);
    const driverCountRef = useRef(0);
    const alertCountRef = useRef(0);
    const [demandHistory, setDemandHistory] = useState<DemandPoint[]>([]);
    const [avgWaitMinutes, setAvgWaitMinutes] = useState<number>(0);
    const [demandIndex, setDemandIndex] = useState<number>(0);

    const mapIncidentToAlert = useCallback((incident: SafetyIncident): SosAlert => {
        return {
            id: incident.id,
            userId: incident.reportedBy?.id ?? 'unknown',
            userName: incident.reportedBy?.fullName ?? undefined,
            tripId: incident.ride?.id,
            severity: incident.severity,
            status: incident.status,
            description: incident.description,
            resolution: incident.resolution,
            timestamp: incident.createdAt,
        };
    }, []);

    const syncIncidentsFromBackend = useCallback(async () => {
        try {
            const incidents = await fetchSafetyIncidents();
            const activeAlerts = incidents
                .filter((incident) => incident.status === 'OPEN' || incident.status === 'INVESTIGATING')
                .map(mapIncidentToAlert);
            setAlerts(activeAlerts);
            alertCountRef.current = activeAlerts.length;
        } catch (error) {
            console.warn('[Fleet] Failed to fetch incidents', error);
        }
    }, [mapIncidentToAlert]);

    const syncMetricsFromBackend = useCallback(async () => {
        try {
            const metrics = await fetchAdminMetricsOverview();
            setDemandHistory(metrics.demandHistory ?? []);
            setAvgWaitMinutes(metrics.avgWaitMinutes ?? 0);
            setDemandIndex(metrics.demandIndex ?? 0);
        } catch (error) {
            console.warn('[Fleet] Failed to fetch admin metrics', error);
        }
    }, []);

    useEffect(() => {
        const token = getAdminAccessToken();
        if (!token) {
            setIsConnected(false);
            return;
        }

        const sock = connectFleetSocket();

        void syncMetricsFromBackend();
        void syncIncidentsFromBackend();

        sock.on('connect', () => setIsConnected(true));
        sock.on('disconnect', () => setIsConnected(false));

        sock.on('fleet_update', (data: DriverPin) => {
            setDrivers((prev) => {
                const next = new Map(prev);
                next.set(data.driverId, data);
                driverCountRef.current = next.size;
                return next;
            });

            // Refresh metrics on live fleet changes to keep cards near real-time.
            void syncMetricsFromBackend();
        });

        sock.on('sos_alert', (data: any) => {
            setAlerts((prev) => {
                const alert: SosAlert = {
                    id: data.incidentId ?? data.id ?? `${Date.now()}`,
                    userId: data.userId ?? 'unknown',
                    userName: data.userName,
                    tripId: data.tripId,
                    lat: data.location?.lat ?? data.lat,
                    lng: data.location?.lng ?? data.lng,
                    severity: data.severity ?? 'HIGH',
                    status: 'OPEN',
                    description: data.description,
                    timestamp: data.timestamp ?? new Date().toISOString(),
                };

                const withoutDup = prev.filter((existing) => existing.id !== alert.id);
                const next = [alert, ...withoutDup].slice(0, 50);
                alertCountRef.current = next.length;
                return next;
            });

            void syncMetricsFromBackend();
        });

        sock.on('incident_updated', () => {
            void syncIncidentsFromBackend();
            void syncMetricsFromBackend();
        });

        const interval = setInterval(() => {
            void syncMetricsFromBackend();
        }, 30_000);

        return () => {
            clearInterval(interval);
            sock.off('fleet_update');
            sock.off('sos_alert');
            sock.off('incident_updated');
        };
    }, []);

    const dismissAlert = useCallback((id: string) => {
        setAlerts((prev) => {
            const next = prev.filter((a) => a.id !== id);
            alertCountRef.current = next.length;
            return next;
        });
    }, []);

    const resolveAlert = useCallback(async (id: string, resolution = 'Resolved by admin') => {
        const previous = alerts;
        setAlerts((prev) => prev.filter((a) => a.id !== id));

        try {
            await resolveSafetyIncident(id, resolution);
            await syncIncidentsFromBackend();
            await syncMetricsFromBackend();
            return { success: true };
        } catch (error) {
            setAlerts(previous);
            alertCountRef.current = previous.length;
            return { success: false, error: error instanceof Error ? error.message : 'Failed to resolve incident' };
        }
    }, [alerts, syncIncidentsFromBackend, syncMetricsFromBackend]);

    const escalateAlert = useCallback(async (id: string) => {
        const previous = alerts;
        setAlerts((prev) => prev.map((a) => (a.id === id ? { ...a, status: 'INVESTIGATING' } : a)));

        try {
            await escalateSafetyIncident(id);
            await syncIncidentsFromBackend();
            return { success: true };
        } catch (error) {
            setAlerts(previous);
            alertCountRef.current = previous.length;
            return { success: false, error: error instanceof Error ? error.message : 'Failed to escalate incident' };
        }
    }, [alerts, syncIncidentsFromBackend]);

    return {
        isConnected,
        drivers: Array.from(drivers.values()),
        driverCount: drivers.size,
        alerts,
        demandHistory,
        demandIndex,
        avgWaitMinutes,
        syncIncidentsFromBackend,
        dismissAlert,
        resolveAlert,
        escalateAlert,
    };
}
