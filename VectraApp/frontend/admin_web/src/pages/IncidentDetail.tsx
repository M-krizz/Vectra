import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { safetyApi } from '../api/endpoints';
import {
    ArrowLeft,
    AlertTriangle,
    Clock,
    CheckCircle2,
    User,
    XCircle,
} from 'lucide-react';

const IncidentDetail: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [incident, setIncident] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [resolution, setResolution] = useState('');
    const [resolving, setResolving] = useState(false);

    useEffect(() => {
        if (!id) return;
        safetyApi.getIncident(id)
            .then((res) => setIncident(res.data))
            .catch(() => { })
            .finally(() => setLoading(false));
    }, [id]);

    const handleResolve = async () => {
        if (!id || !resolution.trim()) return;
        setResolving(true);
        try {
            await safetyApi.resolveIncident(id, resolution.trim());
            setIncident((prev: any) => ({
                ...prev,
                status: 'RESOLVED',
                resolution: resolution.trim(),
                resolvedAt: new Date().toISOString(),
            }));
        } catch { }
        setResolving(false);
    };

    if (loading) {
        return <div className="loading-spinner"><div className="spinner" /></div>;
    }

    if (!incident) {
        return (
            <div className="empty-state">
                <XCircle />
                <h3>Incident not found</h3>
                <button className="btn btn-ghost" onClick={() => navigate('/incidents')}>
                    <ArrowLeft size={16} /> Back to Incidents
                </button>
            </div>
        );
    }

    const severityBadge = (sev: string) => {
        switch (sev) {
            case 'CRITICAL': return 'badge-danger';
            case 'HIGH': return 'badge-warning';
            case 'MEDIUM': return 'badge-info';
            default: return 'badge-muted';
        }
    };

    const statusBadge = (s: string) => {
        switch (s) {
            case 'OPEN': return 'badge-danger';
            case 'INVESTIGATING': return 'badge-warning';
            case 'RESOLVED': return 'badge-success';
            default: return 'badge-muted';
        }
    };

    return (
        <div>
            <div className="page-header">
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <button className="btn btn-ghost btn-sm" onClick={() => navigate('/incidents')}>
                        <ArrowLeft size={16} />
                    </button>
                    <div>
                        <h1>Incident Details</h1>
                        <p>ID: {incident.id}</p>
                    </div>
                </div>
            </div>

            <div className="detail-grid">
                {/* Main Info */}
                <div className="card">
                    <div className="card-header">
                        <h3>Incident Information</h3>
                        <span className={`badge ${statusBadge(incident.status)}`}>
                            {incident.status === 'OPEN' && <Clock size={10} />}
                            {incident.status === 'RESOLVED' && <CheckCircle2 size={10} />}
                            {incident.status}
                        </span>
                    </div>
                    <div className="card-body">
                        <div className="detail-field">
                            <div className="label">Severity</div>
                            <div className="value">
                                <span className={`badge ${severityBadge(incident.severity)}`}>
                                    {(incident.severity === 'CRITICAL' || incident.severity === 'HIGH') && (
                                        <AlertTriangle size={10} />
                                    )}
                                    {incident.severity}
                                </span>
                            </div>
                        </div>
                        <div className="detail-field">
                            <div className="label">Description</div>
                            <div className="value" style={{ lineHeight: 1.7 }}>
                                {incident.description}
                            </div>
                        </div>
                        <div className="detail-field">
                            <div className="label"><Clock size={12} /> Reported At</div>
                            <div className="value">
                                {incident.createdAt
                                    ? new Date(incident.createdAt).toLocaleString()
                                    : '—'}
                            </div>
                        </div>
                        {incident.reportedBy && (
                            <div className="detail-field">
                                <div className="label"><User size={12} /> Reported By</div>
                                <div className="value">
                                    {incident.reportedBy.fullName || incident.reportedBy.email || incident.reportedBy.id || '—'}
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                {/* Resolution / Actions */}
                <div className="card">
                    <div className="card-header">
                        <h3>Resolution</h3>
                    </div>
                    <div className="card-body">
                        {incident.status === 'RESOLVED' || incident.status === 'DISMISSED' ? (
                            <>
                                <div className="detail-field">
                                    <div className="label"><CheckCircle2 size={12} /> Resolution</div>
                                    <div className="value" style={{ lineHeight: 1.7 }}>
                                        {incident.resolution || '—'}
                                    </div>
                                </div>
                                {incident.resolvedAt && (
                                    <div className="detail-field">
                                        <div className="label">Resolved At</div>
                                        <div className="value">
                                            {new Date(incident.resolvedAt).toLocaleString()}
                                        </div>
                                    </div>
                                )}
                                {incident.resolvedById && (
                                    <div className="detail-field">
                                        <div className="label">Resolved By</div>
                                        <div className="value">{incident.resolvedById}</div>
                                    </div>
                                )}
                            </>
                        ) : (
                            <>
                                <p style={{
                                    color: 'var(--color-text-secondary)',
                                    marginBottom: 'var(--space-4)',
                                    fontSize: 'var(--font-size-sm)',
                                }}>
                                    This incident is still open. Provide a resolution summary below.
                                </p>
                                <div className="form-group">
                                    <label htmlFor="resolve-detail">Resolution Summary</label>
                                    <textarea
                                        id="resolve-detail"
                                        rows={4}
                                        value={resolution}
                                        onChange={(e) => setResolution(e.target.value)}
                                        placeholder="Describe how this incident was resolved…"
                                        style={{ resize: 'vertical', minHeight: '100px' }}
                                    />
                                </div>
                                <div style={{ marginTop: 'var(--space-4)' }}>
                                    <button
                                        className="btn btn-success"
                                        onClick={handleResolve}
                                        disabled={!resolution.trim() || resolving}
                                    >
                                        {resolving ? 'Resolving…' : 'Mark as Resolved'}
                                    </button>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default IncidentDetail;
