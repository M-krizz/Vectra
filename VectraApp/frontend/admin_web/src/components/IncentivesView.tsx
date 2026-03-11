import React, { useEffect, useState, useCallback } from 'react'
import { authHeadersOrThrow } from '../services/adminSession'
import { RefreshCw } from 'lucide-react'

interface AdminIncentive {
    id: string
    driverUserId: string
    driverName: string | null
    title: string
    description: string
    rewardAmount: number
    currentProgress: number
    targetProgress: number
    isCompleted: boolean
    expiresAt: string | null
    createdAt: string
}

function ProgressBar({ current, target }: { current: number; target: number }) {
    const pct = target > 0 ? Math.min(100, Math.round((current / target) * 100)) : 0
    return (
        <div style={{ width: '100%', height: 6, borderRadius: 4, background: 'rgba(255,255,255,0.08)', overflow: 'hidden' }}>
            <div style={{
                width: `${pct}%`,
                height: '100%',
                borderRadius: 4,
                background: pct >= 100 ? 'var(--success, #22c55e)' : 'var(--primary)',
                transition: 'width 0.3s',
            }} />
        </div>
    )
}

export function IncentivesView() {
    const [incentives, setIncentives] = useState<AdminIncentive[]>([])
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [filter, setFilter] = useState<'ALL' | 'ACTIVE' | 'COMPLETED'>('ALL')

    const fetchIncentives = useCallback(async () => {
        setLoading(true)
        setError(null)
        try {
            const res = await fetch('/api/v1/admin/incentives', {
                headers: authHeadersOrThrow(false),
            })
            if (!res.ok) {
                const body = await res.json().catch(() => ({}))
                throw new Error((body as any)?.message ?? `Error ${res.status}`)
            }
            setIncentives(await res.json())
        } catch (e: any) {
            setError(e.message ?? 'Failed to load incentives')
        } finally {
            setLoading(false)
        }
    }, [])

    useEffect(() => { fetchIncentives() }, [fetchIncentives])

    const filtered = incentives.filter((inc) => {
        if (filter === 'COMPLETED') return inc.isCompleted
        if (filter === 'ACTIVE') return !inc.isCompleted
        return true
    })

    return (
        <div className="safety-view glass">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
                <h3 style={{ margin: 0 }}>Driver Incentives</h3>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                    <div style={{ display: 'flex', gap: 6 }}>
                        {(['ALL', 'ACTIVE', 'COMPLETED'] as const).map((f) => (
                            <button
                                key={f}
                                className="action-btn"
                                style={{ fontSize: 12, padding: '4px 12px', opacity: filter === f ? 1 : 0.5 }}
                                onClick={() => setFilter(f)}
                            >
                                {f}
                            </button>
                        ))}
                    </div>
                    <button className="action-btn" onClick={fetchIncentives} disabled={loading}>
                        <RefreshCw size={14} style={{ marginRight: 4 }} />
                        {loading ? 'Loading…' : 'Refresh'}
                    </button>
                </div>
            </div>

            {error && <p style={{ color: 'var(--danger)', marginBottom: 12 }}>{error}</p>}

            <table>
                <thead>
                    <tr>
                        <th>Driver</th>
                        <th>Title</th>
                        <th>Reward (₹)</th>
                        <th>Progress</th>
                        <th>Status</th>
                        <th>Expires</th>
                        <th>Created</th>
                    </tr>
                </thead>
                <tbody>
                    {!loading && filtered.length === 0 && (
                        <tr>
                            <td colSpan={7} style={{ textAlign: 'center', color: 'var(--text-dim)', padding: 32 }}>
                                No incentives found
                            </td>
                        </tr>
                    )}
                    {filtered.map((inc) => (
                        <tr key={inc.id}>
                            <td>
                                <div style={{ fontSize: 14 }}>{inc.driverName ?? 'Unknown Driver'}</div>
                                <div style={{ fontSize: 11, color: 'var(--text-dim)', fontFamily: 'monospace' }}>{inc.driverUserId.substring(0, 8)}…</div>
                            </td>
                            <td>
                                <div style={{ fontSize: 14 }}>{inc.title}</div>
                                {inc.description && <div style={{ fontSize: 11, color: 'var(--text-dim)' }}>{inc.description.substring(0, 60)}{inc.description.length > 60 ? '…' : ''}</div>}
                            </td>
                            <td style={{ fontWeight: 600, color: 'var(--primary)' }}>₹{Number(inc.rewardAmount).toLocaleString()}</td>
                            <td style={{ minWidth: 120 }}>
                                <div style={{ marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>
                                    {inc.currentProgress} / {inc.targetProgress}
                                </div>
                                <ProgressBar current={inc.currentProgress} target={inc.targetProgress} />
                            </td>
                            <td>
                                <span className={`badge ${inc.isCompleted ? '' : 'danger'}`} style={inc.isCompleted ? { backgroundColor: 'rgba(34,197,94,0.15)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.3)' } : {}}>
                                    {inc.isCompleted ? 'Completed' : 'Active'}
                                </span>
                            </td>
                            <td style={{ fontSize: 12, color: 'var(--text-dim)' }}>
                                {inc.expiresAt ? new Date(inc.expiresAt).toLocaleDateString() : '–'}
                            </td>
                            <td style={{ fontSize: 12, color: 'var(--text-dim)' }}>
                                {new Date(inc.createdAt).toLocaleDateString()}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}
