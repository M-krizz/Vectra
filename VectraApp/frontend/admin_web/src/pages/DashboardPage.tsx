import { useEffect, useState } from 'react';
import { listUsers, type User } from '../services/userService';
import {
    LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
    AreaChart, Area
} from 'recharts';

// Mock data for charts
const TRIP_DATA = [
    { name: 'Mon', trips: 145 },
    { name: 'Tue', trips: 230 },
    { name: 'Wed', trips: 280 },
    { name: 'Thu', trips: 260 },
    { name: 'Fri', trips: 390 },
    { name: 'Sat', trips: 450 },
    { name: 'Sun', trips: 380 },
];

const REVENUE_DATA = [
    { name: 'Mon', revenue: 2400 },
    { name: 'Tue', revenue: 4130 },
    { name: 'Wed', revenue: 5200 },
    { name: 'Thu', revenue: 4800 },
    { name: 'Fri', revenue: 7900 },
    { name: 'Sat', revenue: 9500 },
    { name: 'Sun', revenue: 8100 },
];

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

            {/* Charts Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr)', gap: 24, marginBottom: 24 }}>
                <div className="card">
                    <div className="card-header">
                        <h3>Weekly Trips</h3>
                    </div>
                    <div className="card-body" style={{ height: 300, padding: '16px 0' }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={TRIP_DATA} margin={{ top: 5, right: 30, left: 10, bottom: 5 }}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#2d3748" vertical={false} />
                                <XAxis dataKey="name" stroke="#a0aec0" tick={{ fill: '#a0aec0' }} />
                                <YAxis stroke="#a0aec0" tick={{ fill: '#a0aec0' }} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: '#1e2532', borderColor: '#2d3748', color: '#fff', borderRadius: 8 }}
                                    itemStyle={{ color: '#10b981', fontWeight: 600 }}
                                />
                                <Line type="monotone" dataKey="trips" stroke="#10b981" strokeWidth={3} dot={{ r: 4, fill: '#10b981', strokeWidth: 0 }} activeDot={{ r: 8 }} />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="card">
                    <div className="card-header">
                        <h3>Weekly Platform Revenue</h3>
                    </div>
                    <div className="card-body" style={{ height: 300, padding: '16px 0' }}>
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={REVENUE_DATA} margin={{ top: 5, right: 30, left: 10, bottom: 5 }}>
                                <defs>
                                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#2d3748" vertical={false} />
                                <XAxis dataKey="name" stroke="#a0aec0" tick={{ fill: '#a0aec0' }} />
                                <YAxis stroke="#a0aec0" tick={{ fill: '#a0aec0' }} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: '#1e2532', borderColor: '#2d3748', color: '#fff', borderRadius: 8 }}
                                    itemStyle={{ color: '#3b82f6', fontWeight: 600 }}
                                    formatter={(value: any) => [`$${value}`, 'Revenue']}
                                />
                                <Area type="monotone" dataKey="revenue" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
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
