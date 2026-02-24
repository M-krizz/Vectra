import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { safetyApi } from '../api/endpoints';
import {
    Search,
    AlertTriangle,
    Filter,
    CheckCircle2,
    Clock,
    Eye,
} from 'lucide-react';

const Incidents: React.FC = () => {
    const navigate = useNavigate();
    const [incidents, setIncidents] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('ALL');
    const [severityFilter, setSeverityFilter] = useState('ALL');

    // Resolve modal
    const [resolveId, setResolveId] = useState<string | null>(null);
    const [resolution, setResolution] = useState('');
    const [resolving, setResolving] = useState(false);

    useEffect(() => {
        fetchIncidents();
    }, []);

    const fetchIncidents = () => {
        safetyApi.listIncidents()
            .then((res) => setIncidents(Array.isArray(res.data) ? res.data : []))
            .catch(() => setIncidents([]))
            .finally(() => setLoading(false));
    };

    const handleResolve = async () => {
        if (!resolveId || !resolution.trim()) return;
        setResolving(true);
        try {
            await safetyApi.resolveIncident(resolveId, resolution.trim());
            setIncidents((prev) =>
                prev.map((i) =>
                    i.id === resolveId ? { ...i, status: 'RESOLVED', resolution: resolution.trim() } : i,
                ),
            );
            setResolveId(null);
            setResolution('');
        } catch { }
        setResolving(false);
    };

    const filtered = incidents.filter((i) => {
        const matchSearch =
            !search || (i.description || '').toLowerCase().includes(search.toLowerCase());
        const matchStatus = statusFilter === 'ALL' || i.status === statusFilter;
        const matchSeverity = severityFilter === 'ALL' || i.severity === severityFilter;
        return matchSearch && matchStatus && matchSeverity;
    });

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

    if (loading) {
        return <div className="loading-spinner"><div className="spinner" /></div>;
    }

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1>Safety & Incidents</h1>
                    <p>Monitor and resolve platform incidents</p>
                </div>
                <div style={{ display: 'flex', gap: '8px' }}>
                    <span className="badge badge-danger">
                        {incidents.filter((i) => i.status === 'OPEN').length} Open
                    </span>
                    <span className="badge badge-warning">
                        {incidents.filter((i) => i.status === 'INVESTIGATING').length} Investigating
                    </span>
                </div>
            </div>

            {/* Toolbar */}
            <div className="toolbar">
                <div className="search-wrapper">
                    <Search />
                    <input
                        type="text"
                        placeholder="Search incidents…"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>
                <select
                    className="filter-select"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                >
                    <option value="ALL">All Status</option>
                    <option value="OPEN">Open</option>
                    <option value="INVESTIGATING">Investigating</option>
                    <option value="RESOLVED">Resolved</option>
                    <option value="DISMISSED">Dismissed</option>
                </select>
                <select
                    className="filter-select"
                    value={severityFilter}
                    onChange={(e) => setSeverityFilter(e.target.value)}
                >
                    <option value="ALL">All Severity</option>
                    <option value="CRITICAL">Critical</option>
                    <option value="HIGH">High</option>
                    <option value="MEDIUM">Medium</option>
                    <option value="LOW">Low</option>
                </select>
            </div>

            {/* Table */}
            <div className="card">
                <div className="data-table">
                    {filtered.length === 0 ? (
                        <div className="empty-state">
                            <CheckCircle2 />
                            <h3>No incidents found</h3>
                            <p>Everything looks safe!</p>
                        </div>
                    ) : (
                        <table>
                            <thead>
                                <tr>
                                    <th>Description</th>
                                    <th>Severity</th>
                                    <th>Status</th>
                                    <th>Reported</th>
                                    <th style={{ width: 140 }}>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filtered.map((i) => (
                                    <tr key={i.id}>
                                        <td style={{
                                            maxWidth: 320,
                                            overflow: 'hidden',
                                            textOverflow: 'ellipsis',
                                            whiteSpace: 'nowrap',
                                        }}>
                                            {i.description}
                                        </td>
                                        <td>
                                            <span className={`badge ${severityBadge(i.severity)}`}>
                                                {(i.severity === 'CRITICAL' || i.severity === 'HIGH') && (
                                                    <AlertTriangle size={10} />
                                                )}
                                                {i.severity}
                                            </span>
                                        </td>
                                        <td>
                                            <span className={`badge ${statusBadge(i.status)}`}>
                                                {i.status === 'OPEN' && <Clock size={10} />}
                                                {i.status}
                                            </span>
                                        </td>
                                        <td style={{ color: 'var(--color-text-muted)', fontSize: '12px' }}>
                                            {i.createdAt
                                                ? new Date(i.createdAt).toLocaleDateString()
                                                : '—'}
                                        </td>
                                        <td>
                                            <div style={{ display: 'flex', gap: '6px' }}>
                                                <button
                                                    className="btn btn-ghost btn-sm"
                                                    onClick={() => navigate(`/incidents/${i.id}`)}
                                                >
                                                    <Eye size={14} /> View
                                                </button>
                                                {(i.status === 'OPEN' || i.status === 'INVESTIGATING') && (
                                                    <button
                                                        className="btn btn-success btn-sm"
                                                        onClick={() => setResolveId(i.id)}
                                                    >
                                                        Resolve
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>

            {/* Resolve Modal */}
            {resolveId && (
                <div className="modal-overlay" onClick={() => setResolveId(null)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <h2>Resolve Incident</h2>
                        <div className="form-group">
                            <label htmlFor="resolve-text">Resolution Summary</label>
                            <textarea
                                id="resolve-text"
                                rows={4}
                                value={resolution}
                                onChange={(e) => setResolution(e.target.value)}
                                placeholder="Describe the resolution…"
                                style={{ resize: 'vertical', minHeight: '100px' }}
                            />
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-ghost" onClick={() => setResolveId(null)}>
                                Cancel
                            </button>
                            <button
                                className="btn btn-success"
                                onClick={handleResolve}
                                disabled={!resolution.trim() || resolving}
                            >
                                {resolving ? 'Resolving…' : 'Mark as Resolved'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Incidents;
