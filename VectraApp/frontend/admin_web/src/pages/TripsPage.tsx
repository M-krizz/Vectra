import { useState } from 'react';
import { getTrip, type Trip } from '../services/tripService';

export default function TripsPage() {
    const [tripId, setTripId] = useState('');
    const [trip, setTrip] = useState<Trip | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!tripId.trim()) return;
        setLoading(true);
        setError('');
        setTrip(null);

        try {
            const data = await getTrip(tripId.trim());
            setTrip(data);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Trip not found');
        } finally {
            setLoading(false);
        }
    };

    const statusBadge = (status: string) => {
        const map: Record<string, string> = {
            REQUESTED: 'info',
            ASSIGNED: 'info',
            ARRIVING: 'warning',
            IN_PROGRESS: 'warning',
            COMPLETED: 'success',
            CANCELLED: 'danger',
        };
        return <span className={`badge ${map[status] || 'neutral'}`}>{status}</span>;
    };

    return (
        <div className="fade-in">
            <div className="page-header">
                <div>
                    <h2>Trip Lookup</h2>
                    <p>Search for a trip by its ID</p>
                </div>
            </div>

            {/* Search */}
            <div className="card" style={{ marginBottom: 24 }}>
                <div className="card-body">
                    <form onSubmit={handleSearch} style={{ display: 'flex', gap: 12, alignItems: 'flex-end' }}>
                        <div className="form-group" style={{ flex: 1, marginBottom: 0 }}>
                            <label htmlFor="trip-id">Trip ID (UUID)</label>
                            <input
                                id="trip-id"
                                className="form-input"
                                placeholder="e.g. a1b2c3d4-5678-…"
                                value={tripId}
                                onChange={(e) => setTripId(e.target.value)}
                            />
                        </div>
                        <button className="btn btn-primary" type="submit" disabled={loading}>
                            {loading ? 'Searching…' : '🔍 Search'}
                        </button>
                    </form>
                </div>
            </div>

            {error && (
                <div className="login-error" style={{ marginBottom: 18 }}>{error}</div>
            )}

            {/* Trip Details */}
            {trip && (
                <div className="card">
                    <div className="card-header">
                        <h3>Trip {trip.id.slice(0, 8)}…</h3>
                        {statusBadge(trip.status)}
                    </div>
                    <div className="card-body">
                        <div className="detail-grid">
                            <div>
                                <div className="detail-row">
                                    <span className="detail-label">Trip ID</span>
                                    <span className="detail-value" style={{ fontSize: '0.78rem', wordBreak: 'break-all' }}>{trip.id}</span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Driver User ID</span>
                                    <span className="detail-value" style={{ fontSize: '0.78rem', wordBreak: 'break-all' }}>
                                        {trip.driverUserId || '—'}
                                    </span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Status</span>
                                    <span className="detail-value">{statusBadge(trip.status)}</span>
                                </div>
                            </div>
                            <div>
                                <div className="detail-row">
                                    <span className="detail-label">Assigned At</span>
                                    <span className="detail-value">
                                        {trip.assignedAt ? new Date(trip.assignedAt).toLocaleString() : '—'}
                                    </span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Started At</span>
                                    <span className="detail-value">
                                        {trip.startAt ? new Date(trip.startAt).toLocaleString() : '—'}
                                    </span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Ended At</span>
                                    <span className="detail-value">
                                        {trip.endAt ? new Date(trip.endAt).toLocaleString() : '—'}
                                    </span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Created</span>
                                    <span className="detail-value">
                                        {new Date(trip.createdAt).toLocaleString()}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {!trip && !loading && !error && (
                <div className="empty-state">
                    <div className="empty-icon">🚗</div>
                    <p>Enter a Trip ID above to view trip details</p>
                </div>
            )}
        </div>
    );
}
