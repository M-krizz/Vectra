import { useEffect, useState } from 'react';
import {
    listIncidents,
    resolveIncident,
    type Incident,
} from '../services/safetyService';

export default function SafetyPage() {
    const [incidents, setIncidents] = useState<Incident[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Resolve modal
    const [resolveTarget, setResolveTarget] = useState<Incident | null>(null);
    const [resolution, setResolution] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    const fetchIncidents = () => {
        setLoading(true);
        listIncidents()
            .then(setIncidents)
            .catch((e) => setError(e.message))
            .finally(() => setLoading(false));
    };

    useEffect(() => {
        fetchIncidents();
    }, []);

    const handleResolve = async () => {
        if (!resolveTarget || !resolution.trim()) return;
        setActionLoading(true);
        try {
            await resolveIncident(resolveTarget.id, resolution);
            setResolveTarget(null);
            setResolution('');
            fetchIncidents();
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : 'Failed to resolve');
        } finally {
            setActionLoading(false);
        }
    };

    const statusBadge = (status: string) => {
        const map: Record<string, string> = {
            OPEN: 'warning',
            RESOLVED: 'success',
            DISMISSED: 'neutral',
        };
        return <span className={`badge ${map[status] || 'info'}`}>{status}</span>;
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="spinner" />
                <span className="loading-text">Loading incidents…</span>
            </div>
        );
    }

    return (
        <div className="fade-in">
            <div className="page-header">
                <div>
                    <h2>Safety &amp; Incidents</h2>
                    <p>{incidents.length} incident{incidents.length !== 1 ? 's' : ''} reported</p>
                </div>
                <button className="btn btn-ghost" onClick={fetchIncidents}>
                    🔄 Refresh
                </button>
            </div>

            {error && <div className="login-error" style={{ marginBottom: 18 }}>{error}</div>}

            {incidents.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">✅</div>
                    <p>No incidents reported</p>
                </div>
            ) : (
                <div className="card">
                    <div className="card-body" style={{ padding: 0 }}>
                        <div className="table-wrapper">
                            <table>
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Description</th>
                                        <th>Status</th>
                                        <th>Reported</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {incidents.map((inc) => (
                                        <tr key={inc.id}>
                                            <td style={{ fontFamily: 'monospace', fontSize: '0.78rem' }}>
                                                {inc.id.slice(0, 8)}…
                                            </td>
                                            <td style={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                                {inc.description}
                                            </td>
                                            <td>{statusBadge(inc.status)}</td>
                                            <td style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                                                {new Date(inc.createdAt).toLocaleString()}
                                            </td>
                                            <td>
                                                {inc.status !== 'RESOLVED' ? (
                                                    <button
                                                        className="btn btn-success btn-sm"
                                                        onClick={() => setResolveTarget(inc)}
                                                    >
                                                        ✓ Resolve
                                                    </button>
                                                ) : (
                                                    <span style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                                                        {inc.resolution}
                                                    </span>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}

            {/* Resolve Modal */}
            {resolveTarget && (
                <div className="modal-overlay" onClick={() => setResolveTarget(null)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <h3>Resolve Incident</h3>
                        <p style={{ color: 'var(--text-secondary)', marginBottom: 12, fontSize: '0.85rem' }}>
                            {resolveTarget.description}
                        </p>
                        <div className="form-group">
                            <label htmlFor="resolution">Resolution</label>
                            <textarea
                                id="resolution"
                                className="form-input"
                                placeholder="Describe the resolution…"
                                value={resolution}
                                onChange={(e) => setResolution(e.target.value)}
                            />
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-ghost" onClick={() => setResolveTarget(null)}>
                                Cancel
                            </button>
                            <button
                                className="btn btn-success"
                                onClick={handleResolve}
                                disabled={actionLoading || !resolution.trim()}
                            >
                                {actionLoading ? 'Resolving…' : 'Confirm Resolve'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
