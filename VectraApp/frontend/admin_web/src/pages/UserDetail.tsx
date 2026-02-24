import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { adminApi } from '../api/endpoints';
import {
    ArrowLeft,
    Shield,
    ShieldOff,
    Mail,
    Phone,
    Calendar,
    User,
    Car,
    Star,
    CheckCircle2,
    XCircle,
    Clock,
} from 'lucide-react';

const UserDetail: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [user, setUser] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState(false);
    const [showSuspendModal, setShowSuspendModal] = useState(false);
    const [suspendReason, setSuspendReason] = useState('');

    useEffect(() => {
        if (!id) return;
        adminApi.getUserDetails(id)
            .then((res) => setUser(res.data))
            .catch(() => { })
            .finally(() => setLoading(false));
    }, [id]);

    const handleSuspend = async () => {
        if (!id || !suspendReason.trim()) return;
        setActionLoading(true);
        try {
            await adminApi.suspendUser(id, suspendReason.trim());
            setUser((prev: any) => ({ ...prev, status: 'SUSPENDED', isSuspended: true, suspensionReason: suspendReason }));
            setShowSuspendModal(false);
            setSuspendReason('');
        } catch { }
        setActionLoading(false);
    };

    const handleReinstate = async () => {
        if (!id) return;
        setActionLoading(true);
        try {
            await adminApi.reinstateUser(id);
            setUser((prev: any) => ({ ...prev, status: 'ACTIVE', isSuspended: false, suspensionReason: null }));
        } catch { }
        setActionLoading(false);
    };

    if (loading) {
        return <div className="loading-spinner"><div className="spinner" /></div>;
    }

    if (!user) {
        return (
            <div className="empty-state">
                <XCircle />
                <h3>User not found</h3>
                <button className="btn btn-ghost" onClick={() => navigate('/users')}>
                    <ArrowLeft size={16} /> Back to Users
                </button>
            </div>
        );
    }

    const driverProfile = user.driverProfile;

    return (
        <div>
            <div className="page-header">
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <button className="btn btn-ghost btn-sm" onClick={() => navigate('/users')}>
                        <ArrowLeft size={16} />
                    </button>
                    <div>
                        <h1>{user.fullName || 'Unnamed User'}</h1>
                        <p>User ID: {user.id}</p>
                    </div>
                </div>
                <div className="detail-actions">
                    {user.status === 'ACTIVE' ? (
                        <button
                            className="btn btn-danger"
                            onClick={() => setShowSuspendModal(true)}
                            disabled={actionLoading}
                        >
                            <ShieldOff size={16} /> Suspend User
                        </button>
                    ) : user.status === 'SUSPENDED' ? (
                        <button
                            className="btn btn-success"
                            onClick={handleReinstate}
                            disabled={actionLoading}
                        >
                            <Shield size={16} /> Reinstate User
                        </button>
                    ) : null}
                </div>
            </div>

            <div className="detail-grid">
                {/* Profile Card */}
                <div className="card">
                    <div className="card-header">
                        <h3>Profile Information</h3>
                        <span
                            className={`badge ${user.status === 'ACTIVE' ? 'badge-success' :
                                    user.status === 'SUSPENDED' ? 'badge-danger' : 'badge-muted'
                                }`}
                        >
                            {user.status}
                        </span>
                    </div>
                    <div className="card-body">
                        <div className="detail-field">
                            <div className="label"><User size={12} /> Full Name</div>
                            <div className="value">{user.fullName || '—'}</div>
                        </div>
                        <div className="detail-field">
                            <div className="label"><Mail size={12} /> Email</div>
                            <div className="value">{user.email || '—'}</div>
                        </div>
                        <div className="detail-field">
                            <div className="label"><Phone size={12} /> Phone</div>
                            <div className="value">{user.phone || '—'}</div>
                        </div>
                        <div className="detail-field">
                            <div className="label">Role</div>
                            <div className="value">
                                <span
                                    className={`badge ${user.role === 'ADMIN' ? 'badge-purple' :
                                            user.role === 'DRIVER' ? 'badge-info' : 'badge-brand'
                                        }`}
                                >
                                    {user.role}
                                </span>
                            </div>
                        </div>
                        <div className="detail-field">
                            <div className="label"><Calendar size={12} /> Joined</div>
                            <div className="value">
                                {user.createdAt ? new Date(user.createdAt).toLocaleDateString('en-US', {
                                    year: 'numeric', month: 'long', day: 'numeric',
                                }) : '—'}
                            </div>
                        </div>
                        <div className="detail-field">
                            <div className="label"><Clock size={12} /> Last Login</div>
                            <div className="value">
                                {user.lastLoginAt
                                    ? new Date(user.lastLoginAt).toLocaleString()
                                    : 'Never'}
                            </div>
                        </div>
                        {user.isSuspended && user.suspensionReason && (
                            <div className="detail-field">
                                <div className="label" style={{ color: 'var(--color-danger)' }}>Suspension Reason</div>
                                <div className="value">{user.suspensionReason}</div>
                            </div>
                        )}
                    </div>
                </div>

                {/* Verification & Driver Card */}
                <div className="card">
                    <div className="card-header">
                        <h3>{user.role === 'DRIVER' ? 'Driver Profile' : 'Account Details'}</h3>
                    </div>
                    <div className="card-body">
                        <div className="detail-field">
                            <div className="label">Verified</div>
                            <div className="value">
                                {user.isVerified ? (
                                    <span className="badge badge-success"><CheckCircle2 size={12} /> Verified</span>
                                ) : (
                                    <span className="badge badge-warning"><Clock size={12} /> Pending</span>
                                )}
                            </div>
                        </div>
                        <div className="detail-field">
                            <div className="label">Account Active</div>
                            <div className="value">
                                {user.isActive ? (
                                    <span className="badge badge-success">Active</span>
                                ) : (
                                    <span className="badge badge-muted">Inactive</span>
                                )}
                            </div>
                        </div>

                        {driverProfile && (
                            <>
                                <hr style={{ border: 'none', borderTop: '1px solid var(--color-border)', margin: 'var(--space-4) 0' }} />
                                <div className="detail-field">
                                    <div className="label"><Car size={12} /> Driver Status</div>
                                    <div className="value">
                                        <span className={`badge ${driverProfile.status === 'VERIFIED' ? 'badge-success' :
                                                driverProfile.status === 'SUSPENDED' ? 'badge-danger' :
                                                    driverProfile.status === 'UNDER_REVIEW' ? 'badge-warning' : 'badge-info'
                                            }`}>
                                            {driverProfile.status}
                                        </span>
                                    </div>
                                </div>
                                <div className="detail-field">
                                    <div className="label">License Number</div>
                                    <div className="value">{driverProfile.licenseNumber || '—'}</div>
                                </div>
                                <div className="detail-field">
                                    <div className="label"><Star size={12} /> Rating</div>
                                    <div className="value">
                                        {Number(driverProfile.ratingAvg).toFixed(1)} / 5.0
                                        <span style={{ color: 'var(--color-text-muted)', fontSize: '12px', marginLeft: '8px' }}>
                                            ({driverProfile.ratingCount} ratings)
                                        </span>
                                    </div>
                                </div>
                                <div className="detail-field">
                                    <div className="label">Completion Rate</div>
                                    <div className="value">{Number(driverProfile.completionRate).toFixed(1)}%</div>
                                </div>
                                <div className="detail-field">
                                    <div className="label">Online Now</div>
                                    <div className="value">
                                        <span className={`badge ${driverProfile.onlineStatus ? 'badge-success' : 'badge-muted'}`}>
                                            {driverProfile.onlineStatus ? 'Online' : 'Offline'}
                                        </span>
                                    </div>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            </div>

            {/* Suspend Modal */}
            {showSuspendModal && (
                <div className="modal-overlay" onClick={() => setShowSuspendModal(false)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <h2>Suspend User</h2>
                        <p style={{ color: 'var(--color-text-secondary)', marginBottom: 'var(--space-4)' }}>
                            This will prevent {user.fullName || 'this user'} from accessing the platform.
                        </p>
                        <div className="form-group">
                            <label htmlFor="suspend-reason">Reason for suspension</label>
                            <textarea
                                id="suspend-reason"
                                rows={3}
                                value={suspendReason}
                                onChange={(e) => setSuspendReason(e.target.value)}
                                placeholder="Enter reason…"
                                style={{ resize: 'vertical', minHeight: '80px' }}
                            />
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-ghost" onClick={() => setShowSuspendModal(false)}>
                                Cancel
                            </button>
                            <button
                                className="btn btn-danger"
                                onClick={handleSuspend}
                                disabled={!suspendReason.trim() || actionLoading}
                            >
                                {actionLoading ? 'Suspending…' : 'Confirm Suspend'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default UserDetail;
