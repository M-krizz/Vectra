import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { adminApi, safetyApi } from '../api/endpoints';
import { useAuth } from '../context/AuthContext';
import {
    Users,
    Car,
    MapPin,
    ShieldAlert,
    TrendingUp,
    ArrowRight,
    AlertTriangle,
    CheckCircle2,
} from 'lucide-react';

interface Stats {
    totalUsers: number;
    totalDrivers: number;
    activeDrivers: number;
    openIncidents: number;
}

const Dashboard: React.FC = () => {
    const { user } = useAuth();
    const navigate = useNavigate();
    const [stats, setStats] = useState<Stats>({
        totalUsers: 0,
        totalDrivers: 0,
        activeDrivers: 0,
        openIncidents: 0,
    });
    const [recentUsers, setRecentUsers] = useState<any[]>([]);
    const [recentIncidents, setRecentIncidents] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const [usersRes, incidentsRes] = await Promise.allSettled([
                    adminApi.listUsers(),
                    safetyApi.listIncidents(),
                ]);

                if (usersRes.status === 'fulfilled') {
                    const users = usersRes.value.data;
                    const allUsers = Array.isArray(users) ? users : [];
                    const drivers = allUsers.filter((u: any) => u.role === 'DRIVER');
                    setStats((prev) => ({
                        ...prev,
                        totalUsers: allUsers.length,
                        totalDrivers: drivers.length,
                        activeDrivers: drivers.filter((d: any) => d.status === 'ACTIVE').length,
                    }));
                    setRecentUsers(allUsers.slice(0, 5));
                }

                if (incidentsRes.status === 'fulfilled') {
                    const incidents = incidentsRes.value.data;
                    const all = Array.isArray(incidents) ? incidents : [];
                    setStats((prev) => ({
                        ...prev,
                        openIncidents: all.filter((i: any) => i.status === 'OPEN' || i.status === 'INVESTIGATING').length,
                    }));
                    setRecentIncidents(all.slice(0, 3));
                }
            } catch {
                // graceful fail
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    if (loading) {
        return (
            <div className="loading-spinner">
                <div className="spinner" />
            </div>
        );
    }

    const statCards = [
        {
            label: 'Total Users',
            value: stats.totalUsers,
            icon: Users,
            color: 'var(--color-brand)',
            bg: 'var(--color-brand-subtle)',
        },
        {
            label: 'Total Drivers',
            value: stats.totalDrivers,
            icon: Car,
            color: 'var(--color-success)',
            bg: 'var(--color-success-subtle)',
        },
        {
            label: 'Active Drivers',
            value: stats.activeDrivers,
            icon: MapPin,
            color: 'var(--color-info)',
            bg: 'var(--color-info-subtle)',
        },
        {
            label: 'Open Incidents',
            value: stats.openIncidents,
            icon: ShieldAlert,
            color: 'var(--color-danger)',
            bg: 'var(--color-danger-subtle)',
        },
    ];

    return (
        <div>
            {/* Welcome */}
            <div className="page-header">
                <div>
                    <h1>Welcome back, {user?.fullName || 'Admin'} 👋</h1>
                    <p>Here's what's happening with Vectra today.</p>
                </div>
            </div>

            {/* Stats Grid */}
            <div className="stats-grid">
                {statCards.map((s) => (
                    <div
                        className="stat-card"
                        key={s.label}
                        style={{ '--stat-accent': s.color } as React.CSSProperties}
                    >
                        <div className="stat-card-icon" style={{ background: s.bg, color: s.color }}>
                            <s.icon />
                        </div>
                        <div className="stat-card-value">{s.value}</div>
                        <div className="stat-card-label">{s.label}</div>
                        <div className="stat-card-change positive">
                            <TrendingUp size={12} /> Live
                        </div>
                    </div>
                ))}
            </div>

            {/* Quick Sections */}
            <div className="charts-grid">
                {/* Recent Users */}
                <div className="card">
                    <div className="card-header">
                        <h3>Recent Users</h3>
                        <button className="btn btn-ghost btn-sm" onClick={() => navigate('/users')}>
                            View All <ArrowRight size={14} />
                        </button>
                    </div>
                    <div className="card-body">
                        {recentUsers.length === 0 ? (
                            <div className="empty-state">
                                <Users />
                                <h3>No users yet</h3>
                            </div>
                        ) : (
                            <div className="data-table">
                                <table>
                                    <thead>
                                        <tr>
                                            <th>Name</th>
                                            <th>Role</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {recentUsers.map((u: any) => (
                                            <tr
                                                key={u.id}
                                                className="clickable"
                                                onClick={() => navigate(`/users/${u.id}`)}
                                            >
                                                <td>{u.fullName || u.email || u.phone || '—'}</td>
                                                <td>
                                                    <span className={`badge ${u.role === 'ADMIN' ? 'badge-purple' :
                                                            u.role === 'DRIVER' ? 'badge-info' : 'badge-brand'
                                                        }`}>{u.role}</span>
                                                </td>
                                                <td>
                                                    <span className={`badge ${u.status === 'ACTIVE' ? 'badge-success' :
                                                            u.status === 'SUSPENDED' ? 'badge-danger' : 'badge-muted'
                                                        }`}>{u.status}</span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                </div>

                {/* Recent Incidents */}
                <div className="card">
                    <div className="card-header">
                        <h3>Recent Incidents</h3>
                        <button className="btn btn-ghost btn-sm" onClick={() => navigate('/incidents')}>
                            View All <ArrowRight size={14} />
                        </button>
                    </div>
                    <div className="card-body">
                        {recentIncidents.length === 0 ? (
                            <div className="empty-state">
                                <CheckCircle2 />
                                <h3>No incidents</h3>
                                <p>Everything looks safe!</p>
                            </div>
                        ) : (
                            <div className="data-table">
                                <table>
                                    <thead>
                                        <tr>
                                            <th>Description</th>
                                            <th>Severity</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {recentIncidents.map((i: any) => (
                                            <tr
                                                key={i.id}
                                                className="clickable"
                                                onClick={() => navigate(`/incidents/${i.id}`)}
                                            >
                                                <td style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                                    {i.description}
                                                </td>
                                                <td>
                                                    <span className={`badge ${i.severity === 'CRITICAL' ? 'badge-danger' :
                                                            i.severity === 'HIGH' ? 'badge-warning' :
                                                                i.severity === 'MEDIUM' ? 'badge-info' : 'badge-muted'
                                                        }`}>
                                                        {i.severity === 'CRITICAL' || i.severity === 'HIGH' ? (
                                                            <AlertTriangle size={10} />
                                                        ) : null}
                                                        {i.severity}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span className={`badge ${i.status === 'OPEN' ? 'badge-danger' :
                                                            i.status === 'INVESTIGATING' ? 'badge-warning' :
                                                                i.status === 'RESOLVED' ? 'badge-success' : 'badge-muted'
                                                        }`}>{i.status}</span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
