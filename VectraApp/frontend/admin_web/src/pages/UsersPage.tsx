import { useEffect, useState } from 'react';
import {
    listUsers,
    getUserDetails,
    suspendUser,
    reinstateUser,
    type User,
    type UserDetails,
} from '../services/userService';

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Detail / action modal state
    const [selectedUser, setSelectedUser] = useState<UserDetails | null>(null);
    const [detailLoading, setDetailLoading] = useState(false);
    const [showSuspendModal, setShowSuspendModal] = useState(false);
    const [suspendReason, setSuspendReason] = useState('');
    const [actionLoading, setActionLoading] = useState(false);

    const fetchUsers = () => {
        setLoading(true);
        listUsers()
            .then(setUsers)
            .catch((e) => setError(e.message))
            .finally(() => setLoading(false));
    };

    useEffect(() => {
        fetchUsers();
    }, []);

    const openDetails = async (userId: string) => {
        setDetailLoading(true);
        setSelectedUser(null);
        try {
            const details = await getUserDetails(userId);
            setSelectedUser(details);
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : 'Failed to load user');
        } finally {
            setDetailLoading(false);
        }
    };

    const handleSuspend = async () => {
        if (!selectedUser) return;
        setActionLoading(true);
        try {
            await suspendUser(selectedUser.user.id, suspendReason || undefined);
            setShowSuspendModal(false);
            setSuspendReason('');
            setSelectedUser(null);
            fetchUsers();
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : 'Failed to suspend');
        } finally {
            setActionLoading(false);
        }
    };

    const handleReinstate = async () => {
        if (!selectedUser) return;
        setActionLoading(true);
        try {
            await reinstateUser(selectedUser.user.id);
            setSelectedUser(null);
            fetchUsers();
        } catch (e: unknown) {
            setError(e instanceof Error ? e.message : 'Failed to reinstate');
        } finally {
            setActionLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="loading-container">
                <div className="spinner" />
                <span className="loading-text">Loading users…</span>
            </div>
        );
    }

    return (
        <div className="fade-in">
            <div className="page-header">
                <div>
                    <h2>User Management</h2>
                    <p>{users.length} users registered</p>
                </div>
            </div>

            {error && <div className="login-error" style={{ marginBottom: 18 }}>{error}</div>}

            {/* Users Table */}
            <div className="card">
                <div className="card-body" style={{ padding: 0 }}>
                    <div className="table-wrapper">
                        <table>
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Contact</th>
                                    <th>Role</th>
                                    <th>Status</th>
                                    <th>Verified</th>
                                    <th>Joined</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {users.map((u) => (
                                    <tr key={u.id}>
                                        <td style={{ fontWeight: 500 }}>{u.fullName || '—'}</td>
                                        <td style={{ color: 'var(--text-secondary)', fontSize: '0.82rem' }}>
                                            {u.email || u.phone || '—'}
                                        </td>
                                        <td>
                                            <span
                                                className={`badge ${u.role === 'ADMIN'
                                                        ? 'info'
                                                        : u.role === 'DRIVER'
                                                            ? 'success'
                                                            : 'neutral'
                                                    }`}
                                            >
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
                                        <td>
                                            {u.isVerified ? (
                                                <span className="badge success">✓</span>
                                            ) : (
                                                <span className="badge warning">Pending</span>
                                            )}
                                        </td>
                                        <td style={{ color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                                            {new Date(u.createdAt).toLocaleDateString()}
                                        </td>
                                        <td>
                                            <button
                                                className="btn btn-ghost btn-sm"
                                                onClick={() => openDetails(u.id)}
                                            >
                                                View
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            {/* User Detail Modal */}
            {(selectedUser || detailLoading) && (
                <div className="modal-overlay" onClick={() => !detailLoading && setSelectedUser(null)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        {detailLoading ? (
                            <div className="loading-container" style={{ padding: 40 }}>
                                <div className="spinner" />
                            </div>
                        ) : selectedUser ? (
                            <>
                                <h3>User Details</h3>

                                <div className="detail-row">
                                    <span className="detail-label">Name</span>
                                    <span className="detail-value">{selectedUser.user.fullName || '—'}</span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Email</span>
                                    <span className="detail-value">{selectedUser.user.email || '—'}</span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Phone</span>
                                    <span className="detail-value">{selectedUser.user.phone || '—'}</span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Role</span>
                                    <span className="detail-value">
                                        <span className={`badge ${selectedUser.user.role === 'ADMIN' ? 'info' : selectedUser.user.role === 'DRIVER' ? 'success' : 'neutral'}`}>
                                            {selectedUser.user.role}
                                        </span>
                                    </span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Status</span>
                                    <span className="detail-value">
                                        {selectedUser.user.isSuspended ? (
                                            <span className="badge danger">Suspended</span>
                                        ) : (
                                            <span className="badge success">Active</span>
                                        )}
                                    </span>
                                </div>
                                {selectedUser.user.suspensionReason && (
                                    <div className="detail-row">
                                        <span className="detail-label">Suspension Reason</span>
                                        <span className="detail-value" style={{ color: 'var(--danger)' }}>
                                            {selectedUser.user.suspensionReason}
                                        </span>
                                    </div>
                                )}
                                <div className="detail-row">
                                    <span className="detail-label">Verified</span>
                                    <span className="detail-value">{selectedUser.user.isVerified ? 'Yes' : 'No'}</span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Joined</span>
                                    <span className="detail-value">
                                        {new Date(selectedUser.user.createdAt).toLocaleString()}
                                    </span>
                                </div>
                                <div className="detail-row">
                                    <span className="detail-label">Last Login</span>
                                    <span className="detail-value">
                                        {selectedUser.user.lastLoginAt
                                            ? new Date(selectedUser.user.lastLoginAt).toLocaleString()
                                            : 'Never'}
                                    </span>
                                </div>

                                {/* Driver Profile */}
                                {selectedUser.driverProfile && (
                                    <>
                                        <h3 style={{ marginTop: 20, fontSize: '0.95rem' }}>Driver Profile</h3>
                                        <div className="detail-row">
                                            <span className="detail-label">Verification</span>
                                            <span className="detail-value">
                                                <span
                                                    className={`badge ${selectedUser.driverProfile.verificationStatus === 'APPROVED'
                                                            ? 'success'
                                                            : selectedUser.driverProfile.verificationStatus === 'REJECTED'
                                                                ? 'danger'
                                                                : 'warning'
                                                        }`}
                                                >
                                                    {selectedUser.driverProfile.verificationStatus}
                                                </span>
                                            </span>
                                        </div>
                                        <div className="detail-row">
                                            <span className="detail-label">Rating</span>
                                            <span className="detail-value">
                                                ⭐ {selectedUser.driverProfile.ratingAvg} ({selectedUser.driverProfile.ratingCount} reviews)
                                            </span>
                                        </div>
                                        <div className="detail-row">
                                            <span className="detail-label">Completion Rate</span>
                                            <span className="detail-value">{selectedUser.driverProfile.completionRate}%</span>
                                        </div>
                                        <div className="detail-row">
                                            <span className="detail-label">Online</span>
                                            <span className="detail-value">
                                                {selectedUser.driverProfile.onlineStatus ? '🟢 Online' : '⚫ Offline'}
                                            </span>
                                        </div>
                                    </>
                                )}

                                {/* Actions */}
                                <div className="modal-actions">
                                    <button className="btn btn-ghost" onClick={() => setSelectedUser(null)}>
                                        Close
                                    </button>
                                    {selectedUser.user.isSuspended ? (
                                        <button
                                            className="btn btn-success"
                                            onClick={handleReinstate}
                                            disabled={actionLoading}
                                        >
                                            {actionLoading ? 'Reinstating…' : '✓ Reinstate'}
                                        </button>
                                    ) : (
                                        <button
                                            className="btn btn-danger"
                                            onClick={() => setShowSuspendModal(true)}
                                        >
                                            🚫 Suspend
                                        </button>
                                    )}
                                </div>
                            </>
                        ) : null}
                    </div>
                </div>
            )}

            {/* Suspend Reason Modal */}
            {showSuspendModal && (
                <div className="modal-overlay" onClick={() => setShowSuspendModal(false)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <h3>Suspend User</h3>
                        <p style={{ color: 'var(--text-secondary)', marginBottom: 16, fontSize: '0.85rem' }}>
                            Provide a reason for suspending <strong>{selectedUser?.user.fullName || selectedUser?.user.email}</strong>.
                        </p>
                        <div className="form-group">
                            <label htmlFor="suspend-reason">Reason</label>
                            <textarea
                                id="suspend-reason"
                                className="form-input"
                                placeholder="Violation of terms of service…"
                                value={suspendReason}
                                onChange={(e) => setSuspendReason(e.target.value)}
                            />
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-ghost" onClick={() => setShowSuspendModal(false)}>
                                Cancel
                            </button>
                            <button
                                className="btn btn-danger"
                                onClick={handleSuspend}
                                disabled={actionLoading}
                            >
                                {actionLoading ? 'Suspending…' : 'Confirm Suspend'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
