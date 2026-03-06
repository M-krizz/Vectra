import { useEffect, useState } from 'react';
import { listUsers, type User } from '../services/userService';

export default function DashboardPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        listUsers()
            .then(setUsers)
            .catch((e) => setError(e.message))
            .finally(() => setLoading(false));
    }, []);

    if (loading) {
        return (
            <div className="loading-container">
                <div className="spinner" />
                <span className="loading-text">Loading dashboard…</span>
            </div>
        );
    }

    if (error) {
        return (
            <div className="empty-state">
                <div className="empty-icon">⚠️</div>
                <p>{error}</p>
            </div>
        );
    }

    const totalUsers = users.length;
    const riders = users.filter((u) => u.role === 'RIDER').length;
    const drivers = users.filter((u) => u.role === 'DRIVER').length;
    const admins = users.filter((u) => u.role === 'ADMIN' || u.role === 'COMMUNITY_ADMIN').length;
    const suspended = users.filter((u) => u.isSuspended).length;
    const recentUsers = users.slice(0, 8);

    return (
        <div className="fade-in">
            <div className="page-header">
                <div>
                    <h2>Dashboard</h2>
                    <p>Overview of the Vectra platform</p>
                </div>
            </div>

            {/* Stats */}
            <div className="stats-grid">
                <div className="stat-card purple">
                    <div className="stat-icon">👥</div>
                    <div className="stat-value">{totalUsers}</div>
                    <div className="stat-label">Total Users</div>
                </div>
                <div className="stat-card blue">
                    <div className="stat-icon">🧑</div>
                    <div className="stat-value">{riders}</div>
                    <div className="stat-label">Riders</div>
                </div>
                <div className="stat-card green">
                    <div className="stat-icon">🚗</div>
                    <div className="stat-value">{drivers}</div>
                    <div className="stat-label">Drivers</div>
                </div>
                <div className="stat-card amber">
                    <div className="stat-icon">🛡️</div>
                    <div className="stat-value">{admins}</div>
                    <div className="stat-label">Admins</div>
                </div>
                <div className="stat-card red">
                    <div className="stat-icon">🚫</div>
                    <div className="stat-value">{suspended}</div>
                    <div className="stat-label">Suspended</div>
                </div>
            </div>

            {/* Recent Users */}
            <div className="card">
                <div className="card-header">
                    <h3>Recent Users</h3>
                </div>
                <div className="card-body">
                    {recentUsers.length === 0 ? (
                        <div className="empty-state">
                            <div className="empty-icon">📭</div>
                            <p>No users found</p>
                        </div>
                    ) : (
                        <div className="table-wrapper">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Name</th>
                                        <th>Email</th>
                                        <th>Role</th>
                                        <th>Status</th>
                                        <th>Joined</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {recentUsers.map((u) => (
                                        <tr key={u.id}>
                                            <td>{u.fullName || '—'}</td>
                                            <td style={{ color: 'var(--text-secondary)' }}>{u.email || u.phone || '—'}</td>
                                            <td>
                                                <span className={`badge ${u.role === 'ADMIN' ? 'info' : u.role === 'DRIVER' ? 'success' : 'neutral'}`}>
                                                    {u.role}
                                                </span>
                                            </td>
                                            <td>
                                                {u.isSuspended ? (
                                                    <span className="badge danger">Suspended</span>
                                                ) : (
                                                    <span className="badge success">Active</span>
                                                )}
                                            </td>
                                            <td style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                                                {new Date(u.createdAt).toLocaleDateString()}
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
    );
}
