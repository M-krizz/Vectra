import React, { useEffect, useState } from 'react';
import { CheckCircle, XCircle, Search } from 'lucide-react';
import { authHeadersOrThrow } from '../services/adminSession';

interface DriverProfile {
    id: string;
    userId: string;
    firstName: string;
    lastName: string;
    licenseNumber: string;
    licenseFileUrl?: string;
    rcNumber: string;
    rcFileUrl?: string;
    status: string;
}

const API_URL = (import.meta as any).env.VITE_API_URL ?? 'http://localhost:3000';

export function UserOpsView() {
    const [pendingDrivers, setPendingDrivers] = useState<DriverProfile[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        fetchPendingDrivers();
    }, []);

    const fetchPendingDrivers = async () => {
        setLoading(true);
        try {
            const res = await fetch(`${API_URL}/api/v1/admin/drivers/pending`, {
                headers: authHeadersOrThrow(),
            });
            if (res.ok) {
                const data = await res.json();
                setPendingDrivers(data);
            }
        } catch (error) {
            console.error("Failed to fetch pending drivers", error);
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateStatus = async (id: string, newStatus: 'APPROVED' | 'REJECTED') => {
        try {
            const res = await fetch(`${API_URL}/api/v1/admin/drivers/${id}/status`, {
                method: 'PATCH',
                headers: authHeadersOrThrow(),
                body: JSON.stringify({ status: newStatus }),
            });

            if (res.ok) {
                // Remove from local list
                setPendingDrivers(prev => prev.filter(d => d.id !== id));
            }
        } catch (error) {
            console.error(`Failed to update driver ${id} status`, error);
        }
    };

    const filteredDrivers = pendingDrivers.filter((driver) => {
        if (!searchTerm.trim()) return true;
        const q = searchTerm.toLowerCase();
        return (
            `${driver.firstName} ${driver.lastName}`.toLowerCase().includes(q) ||
            (driver.licenseNumber || '').toLowerCase().includes(q) ||
            (driver.rcNumber || '').toLowerCase().includes(q)
        );
    });

    if (loading) {
        return (
            <div className="glass" style={{ padding: 32, borderRadius: 24, textAlign: 'center' }}>
                <h3>Loading Pending Approvals...</h3>
            </div>
        );
    }

    return (
        <div className="glass" style={{ padding: 32, borderRadius: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <h3>Pending Driver Approvals ({filteredDrivers.length})</h3>
                <div className="search-container" style={{ width: 250 }}>
                    <Search size={18} className="search-icon" />
                    <input
                        type="text"
                        placeholder="Search drivers..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{ background: 'transparent', border: 'none', color: 'white', outline: 'none', marginLeft: 8 }}
                    />
                </div>
            </div>

            {filteredDrivers.length === 0 ? (
                <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-dim)' }}>
                    <CheckCircle size={48} style={{ margin: '0 auto 16px', opacity: 0.5 }} />
                    <p>All caught up! No drivers waiting for approval.</p>
                </div>
            ) : (
                <table style={{ width: '100%', textAlign: 'left', borderCollapse: 'collapse' }}>
                    <thead>
                        <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
                            <th style={{ padding: '12px 8px', color: 'var(--text-dim)', fontWeight: 500 }}>Driver Name</th>
                            <th style={{ padding: '12px 8px', color: 'var(--text-dim)', fontWeight: 500 }}>License No.</th>
                            <th style={{ padding: '12px 8px', color: 'var(--text-dim)', fontWeight: 500 }}>Documents</th>
                            <th style={{ padding: '12px 8px', color: 'var(--text-dim)', fontWeight: 500, textAlign: 'right' }}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredDrivers.map((driver: DriverProfile) => (
                            <tr key={driver.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                                <td style={{ padding: '16px 8px', fontWeight: 'bold' }}>
                                    {driver.firstName} {driver.lastName}
                                </td>
                                <td style={{ padding: '16px 8px', fontFamily: 'monospace' }}>
                                    {driver.licenseNumber || 'N/A'}
                                </td>
                                <td style={{ padding: '16px 8px' }}>
                                    {driver.licenseFileUrl ? (
                                        <a href={`${API_URL}${driver.licenseFileUrl}`} target="_blank" rel="noreferrer" style={{ color: 'var(--primary)', marginRight: 12, textDecoration: 'none' }}>License</a>
                                    ) : <span style={{ color: 'var(--text-dim)', marginRight: 12 }}>No License</span>}
                                    {driver.rcFileUrl ? (
                                        <a href={`${API_URL}${driver.rcFileUrl}`} target="_blank" rel="noreferrer" style={{ color: 'var(--primary)', textDecoration: 'none' }}>RC Book</a>
                                    ) : <span style={{ color: 'var(--text-dim)' }}>No RC</span>}
                                </td>
                                <td style={{ padding: '16px 8px', textAlign: 'right' }}>
                                    <button
                                        className="action-btn"
                                        style={{ backgroundColor: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: '1px solid rgba(239, 68, 68, 0.3)', marginRight: 8 }}
                                        onClick={() => handleUpdateStatus(driver.id, 'REJECTED')}
                                    >
                                        <XCircle size={14} style={{ marginRight: 4 }} /> Reject
                                    </button>
                                    <button
                                        className="action-btn"
                                        style={{ backgroundColor: 'rgba(34, 197, 94, 0.1)', color: '#22c55e', border: '1px solid rgba(34, 197, 94, 0.3)' }}
                                        onClick={() => handleUpdateStatus(driver.id, 'APPROVED')}
                                    >
                                        <CheckCircle size={14} style={{ marginRight: 4 }} /> Approve
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}
        </div>
    );
}
