import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { adminApi } from '../api/endpoints';
import { Search, UserPlus, Filter } from 'lucide-react';

const Users: React.FC = () => {
    const navigate = useNavigate();
    const [users, setUsers] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('ALL');
    const [statusFilter, setStatusFilter] = useState('ALL');

    useEffect(() => {
        adminApi.listUsers()
            .then((res) => {
                setUsers(Array.isArray(res.data) ? res.data : []);
            })
            .catch(() => setUsers([]))
            .finally(() => setLoading(false));
    }, []);

    const filtered = users.filter((u) => {
        const matchSearch =
            !search ||
            (u.fullName || '').toLowerCase().includes(search.toLowerCase()) ||
            (u.email || '').toLowerCase().includes(search.toLowerCase()) ||
            (u.phone || '').includes(search);
        const matchRole = roleFilter === 'ALL' || u.role === roleFilter;
        const matchStatus = statusFilter === 'ALL' || u.status === statusFilter;
        return matchSearch && matchRole && matchStatus;
    });

    if (loading) {
        return <div className="loading-spinner"><div className="spinner" /></div>;
    }

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1>User Management</h1>
                    <p>Manage riders, drivers, and admin accounts</p>
                </div>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                    <span className="badge badge-brand">{users.length} Total</span>
                </div>
            </div>

            {/* Toolbar */}
            <div className="toolbar">
                <div className="search-wrapper">
                    <Search />
                    <input
                        type="text"
                        placeholder="Search by name, email, or phone…"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>
                <select
                    className="filter-select"
                    value={roleFilter}
                    onChange={(e) => setRoleFilter(e.target.value)}
                >
                    <option value="ALL">All Roles</option>
                    <option value="RIDER">Rider</option>
                    <option value="DRIVER">Driver</option>
                    <option value="ADMIN">Admin</option>
                </select>
                <select
                    className="filter-select"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                >
                    <option value="ALL">All Status</option>
                    <option value="ACTIVE">Active</option>
                    <option value="SUSPENDED">Suspended</option>
                </select>
            </div>

            {/* Table */}
            <div className="card">
                <div className="data-table">
                    {filtered.length === 0 ? (
                        <div className="empty-state">
                            <Filter />
                            <h3>No users found</h3>
                            <p>Try adjusting your search or filters.</p>
                        </div>
                    ) : (
                        <table>
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Email</th>
                                    <th>Phone</th>
                                    <th>Role</th>
                                    <th>Status</th>
                                    <th>Joined</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filtered.map((u: any) => (
                                    <tr
                                        key={u.id}
                                        className="clickable"
                                        onClick={() => navigate(`/users/${u.id}`)}
                                    >
                                        <td>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                                <div
                                                    style={{
                                                        width: 32,
                                                        height: 32,
                                                        borderRadius: '50%',
                                                        background: u.role === 'ADMIN'
                                                            ? 'linear-gradient(135deg, #a855f7, #6366f1)'
                                                            : u.role === 'DRIVER'
                                                                ? 'linear-gradient(135deg, #3b82f6, #06b6d4)'
                                                                : 'linear-gradient(135deg, #6366f1, #818cf8)',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        justifyContent: 'center',
                                                        fontSize: '11px',
                                                        fontWeight: 600,
                                                        color: 'white',
                                                        flexShrink: 0,
                                                    }}
                                                >
                                                    {(u.fullName || u.email || '?')[0].toUpperCase()}
                                                </div>
                                                <span style={{ fontWeight: 500 }}>
                                                    {u.fullName || '—'}
                                                </span>
                                            </div>
                                        </td>
                                        <td style={{ color: 'var(--color-text-secondary)' }}>
                                            {u.email || '—'}
                                        </td>
                                        <td style={{ color: 'var(--color-text-secondary)' }}>
                                            {u.phone || '—'}
                                        </td>
                                        <td>
                                            <span
                                                className={`badge ${u.role === 'ADMIN'
                                                        ? 'badge-purple'
                                                        : u.role === 'DRIVER'
                                                            ? 'badge-info'
                                                            : 'badge-brand'
                                                    }`}
                                            >
                                                {u.role}
                                            </span>
                                        </td>
                                        <td>
                                            <span
                                                className={`badge ${u.status === 'ACTIVE'
                                                        ? 'badge-success'
                                                        : u.status === 'SUSPENDED'
                                                            ? 'badge-danger'
                                                            : 'badge-muted'
                                                    }`}
                                            >
                                                {u.status}
                                            </span>
                                        </td>
                                        <td style={{ color: 'var(--color-text-muted)', fontSize: '12px' }}>
                                            {u.createdAt
                                                ? new Date(u.createdAt).toLocaleDateString()
                                                : '—'}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Users;
