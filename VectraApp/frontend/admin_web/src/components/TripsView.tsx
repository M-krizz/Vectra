import React, { useEffect, useState, useCallback } from 'react'
import { authHeadersOrThrow } from '../services/adminSession'
import { RefreshCw } from 'lucide-react'

type TripStatus = 'REQUESTED' | 'ASSIGNED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'

interface AdminTrip {
    id: string
    status: TripStatus
    vehicleType: string | null
    rideType: string | null
    distanceMeters: number | null
    driverName: string | null
    driverUserId: string | null
    riderCount: number
    createdAt: string
    updatedAt: string
}

const STATUS_COLORS: Record<string, string> = {
    REQUESTED: '#f59e0b',
    ASSIGNED: '#3b82f6',
    IN_PROGRESS: '#8b5cf6',
    COMPLETED: '#22c55e',
    CANCELLED: '#ef4444',
}

const ALL_STATUSES: Array<TripStatus | 'ALL'> = ['ALL', 'REQUESTED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']

function fmt_dist(meters: number | null): string {
    if (meters == null) return '–'
    return meters >= 1000 ? `${(meters / 1000).toFixed(1)} km` : `${meters} m`
}

export function TripsView() {
    const [trips, setTrips] = useState<AdminTrip[]>([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [statusFilter, setStatusFilter] = useState<TripStatus | 'ALL'>('ALL')

    const fetchTrips = useCallback(async () => {
        setLoading(true)
        setError(null)
        try {
            const params = statusFilter !== 'ALL' ? `?status=${statusFilter}` : ''
            const res = await fetch(`/api/v1/admin/trips${params}`, {
                headers: authHeadersOrThrow(false),
            })
            if (!res.ok) {
                const body = await res.json().catch(() => ({}))
                throw new Error((body as any)?.message ?? `Error ${res.status}`)
            }
            setTrips(await res.json())
        } catch (e: any) {
            setError(e.message ?? 'Failed to load trips')
        } finally {
            setLoading(false)
        }
    }, [statusFilter])

    useEffect(() => { fetchTrips() }, [fetchTrips])

    return (
        <div className="safety-view glass">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
                <h3 style={{ margin: 0 }}>All Trips</h3>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                    <div style={{ display: 'flex', gap: 6 }}>
                        {ALL_STATUSES.map((s) => (
                            <button
                                key={s}
                                className="action-btn"
                                style={{
                                    fontSize: 12,
                                    padding: '4px 12px',
                                    opacity: statusFilter === s ? 1 : 0.5,
                                    borderColor: s !== 'ALL' ? STATUS_COLORS[s] : undefined,
                                    color: s !== 'ALL' && statusFilter === s ? STATUS_COLORS[s] : undefined,
                                }}
                                onClick={() => setStatusFilter(s as any)}
                            >
                                {s}
                            </button>
                        ))}
                    </div>
                    <button className="action-btn" onClick={fetchTrips} disabled={loading}>
                        <RefreshCw size={14} style={{ marginRight: 4 }} />
                        {loading ? 'Loading…' : 'Refresh'}
                    </button>
                </div>
            </div>

            {error && <p style={{ color: 'var(--danger)', marginBottom: 12 }}>{error}</p>}

            <table>
                <thead>
                    <tr>
                        <th>Trip ID</th>
                        <th>Status</th>
                        <th>Vehicle</th>
                        <th>Ride Type</th>
                        <th>Distance</th>
                        <th>Riders</th>
                        <th>Driver</th>
                        <th>Created</th>
                    </tr>
                </thead>
                <tbody>
                    {!loading && trips.length === 0 && (
                        <tr>
                            <td colSpan={8} style={{ textAlign: 'center', color: 'var(--text-dim)', padding: 32 }}>
                                No trips found
                            </td>
                        </tr>
                    )}
                    {trips.map((trip) => (
                        <tr key={trip.id}>
                            <td style={{ fontFamily: 'monospace', fontSize: 12 }}>{trip.id.substring(0, 8)}…</td>
                            <td>
                                <span
                                    className="badge"
                                    style={{
                                        backgroundColor: `${STATUS_COLORS[trip.status] ?? '#6b7280'}22`,
                                        color: STATUS_COLORS[trip.status] ?? '#6b7280',
                                        border: `1px solid ${STATUS_COLORS[trip.status] ?? '#6b7280'}44`,
                                    }}
                                >
                                    {trip.status}
                                </span>
                            </td>
                            <td>{trip.vehicleType ?? '–'}</td>
                            <td>{trip.rideType ?? '–'}</td>
                            <td>{fmt_dist(trip.distanceMeters)}</td>
                            <td style={{ textAlign: 'center' }}>{trip.riderCount}</td>
                            <td>{trip.driverName ?? <span style={{ color: 'var(--text-dim)' }}>Unassigned</span>}</td>
                            <td style={{ fontSize: 12, color: 'var(--text-dim)' }}>
                                {new Date(trip.createdAt).toLocaleString()}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}
