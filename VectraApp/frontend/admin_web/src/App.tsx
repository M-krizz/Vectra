import { useState } from 'react'
import {
    LayoutDashboard,
    Map as MapIcon,
    Users,
    ShieldAlert,
    BarChart3,
    Settings,
    Bell,
    Search,
    Zap,
    Navigation,
    Wifi,
    WifiOff,
    X,
    List,
} from 'lucide-react'
import React from 'react'
import {
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
} from 'recharts'
import { useFleetData, SosAlert } from './hooks/useFleetData'
import { FleetMapView } from './components/FleetMapView'
import { UserOpsView } from './components/UserOpsView'
import { TripsView } from './components/TripsView'
import { IncentivesView } from './components/IncentivesView'
import { clearAdminSession, getAdminAccessToken, setAdminAccessToken } from './services/adminSession'
import { fetchAdminMe, requestAdminOtp, verifyAdminOtp } from './services/adminAuth'
import './App.css'

// ─── Nav ────────────────────────────────────────────────────────────────────

function NavItem({ icon, label, active, onClick }: { icon: any, label: string, active?: boolean, onClick: () => void }) {
    return (
        <div className={`nav-item ${active ? 'active' : ''}`} onClick={onClick}>
            {icon}
            <span>{label}</span>
            {active && <div className="active-glow"></div>}
        </div>
    )
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

function StatCard({ title, value, change, icon, color }: any) {
    const isPositive = change?.startsWith('+')
    return (
        <div className="stat-card glass" style={{ borderColor: color ? `${color}44` : '' }}>
            <div className="stat-icon" style={{ backgroundColor: color ? `${color}22` : 'rgba(255,255,255,0.05)', color: color }}>
                {icon}
            </div>
            <div className="stat-body">
                <span className="stat-title">{title}</span>
                <h2 className="stat-value">{value}</h2>
                {change && (
                    <span className="stat-change" style={{ color: isPositive ? 'var(--success)' : 'var(--danger)' }}>
                        {change} <small>vs last hour</small>
                    </span>
                )}
            </div>
        </div>
    )
}

// ─── Views ───────────────────────────────────────────────────────────────────

function DashboardView({ demandHistory, driverCount, alerts, dismissAlert, demandIndex, avgWaitMinutes }: any) {
    return (
        <div className="view-grid">
            <div className="stat-cards">
                <StatCard title="Active Drivers" value={driverCount} change={`+${Math.max(0, driverCount - 2)}`} icon={<Navigation size={24} />} />
                <StatCard title="Demand Index" value={demandIndex} change={demandHistory.length > 1 ? `${(demandHistory[demandHistory.length - 1]?.trips ?? 0) - (demandHistory[demandHistory.length - 2]?.trips ?? 0)}` : undefined} icon={<BarChart3 size={24} />} color="var(--primary)" />
                <StatCard title="Open SOS Alerts" value={alerts.length} change={alerts.length > 0 ? `+${alerts.length}` : '0'} icon={<ShieldAlert size={24} />} color="var(--accent)" />
                <StatCard title="Avg Wait Time" value={`${avgWaitMinutes.toFixed(1)}m`} icon={<Zap size={24} />} color="var(--secondary)" />
            </div>

            <div className="main-grid">
                <div className="chart-container glass">
                    <h3>Real-time Demand Index <span className="live-badge">LIVE</span></h3>
                    <ResponsiveContainer width="100%" height={280}>
                        <LineChart data={demandHistory}>
                            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                            <XAxis dataKey="time" tick={{ fill: 'var(--text-dim)', fontSize: 11 }} />
                            <YAxis tick={{ fill: 'var(--text-dim)', fontSize: 11 }} />
                            <Tooltip
                                contentStyle={{ background: 'var(--bg-card)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8 }}
                                labelStyle={{ color: 'var(--text-dim)' }}
                            />
                            <Line type="monotone" dataKey="trips" stroke="var(--primary)" strokeWidth={2} dot={false} />
                        </LineChart>
                    </ResponsiveContainer>
                </div>

                <div className="recent-activity glass">
                    <h3>SOS Alerts {alerts.length > 0 && <span className="badge danger">{alerts.length}</span>}</h3>
                    {alerts.length === 0 && <p className="no-alerts">No active SOS alerts ✓</p>}
                    {alerts.map((alert: SosAlert) => (
                        <div key={alert.id ?? alert.timestamp} className="alert-item high-priority">
                            <ShieldAlert size={18} />
                            <div className="alert-info">
                                <p>SOS — User {alert.userId?.substring(0, 8)}...</p>
                                <span>{alert.tripId ? `Trip: ${alert.tripId.substring(0, 8)}...` : 'No trip linked'}</span>
                            </div>
                            <button className="view-btn" onClick={() => dismissAlert(alert.id ?? alert.timestamp)}>
                                <X size={14} />
                            </button>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    )
}

// Removed FleetView, imported from components instead

function SafetyView({ alerts, resolveAlert, escalateAlert }: any) {
    const [busy, setBusy] = React.useState<Record<string, boolean>>({})

    const handleResolve = async (id: string) => {
        setBusy((prev: any) => ({ ...prev, [id]: true }))
        const result = await resolveAlert(id)
        setBusy((prev: any) => ({ ...prev, [id]: false }))
        if (!result.success) {
            window.alert(result.error ?? 'Failed to resolve incident')
        }
    }

    const handleEscalate = async (id: string) => {
        setBusy((prev: any) => ({ ...prev, [id]: true }))
        const result = await escalateAlert(id)
        setBusy((prev: any) => ({ ...prev, [id]: false }))
        if (!result.success) {
            window.alert(result.error ?? 'Failed to escalate incident')
        }
    }

    return (
        <div className="safety-view glass">
            <h3>Incident Management</h3>
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Type</th>
                        <th>Trip</th>
                        <th>Location</th>
                        <th>Status</th>
                        <th>Time</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    {alerts.length === 0 && (
                        <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--text-dim)', padding: 32 }}>No active incidents</td></tr>
                    )}
                    {alerts.map((a: SosAlert) => (
                        <tr key={a.id ?? a.timestamp}>
                            <td>{a.userName ?? `${a.userId?.substring(0, 10)}...`}</td>
                            <td><span className="badge danger">SOS</span></td>
                            <td>{a.tripId?.substring(0, 8) ?? '–'}</td>
                            <td>{a.lat ? `${a.lat.toFixed(3)}, ${a.lng?.toFixed(3)}` : '–'}</td>
                            <td>
                                <span className={`badge ${a.status === 'INVESTIGATING' ? '' : 'danger'}`}>
                                    {a.status}
                                </span>
                            </td>
                            <td>{new Date(a.timestamp).toLocaleTimeString()}</td>
                            <td>
                                <button
                                    className="action-btn"
                                    style={{ marginRight: 8 }}
                                    disabled={busy[a.id] || a.status === 'INVESTIGATING'}
                                    onClick={() => handleEscalate(a.id ?? a.timestamp)}
                                >
                                    Escalate
                                </button>
                                <button
                                    className="action-btn"
                                    disabled={busy[a.id]}
                                    onClick={() => handleResolve(a.id ?? a.timestamp)}
                                >
                                    Resolve
                                </button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    )
}

// ─── Root ────────────────────────────────────────────────────────────────────

function App() {
    const [tokenInput, setTokenInput] = useState('')
    const [identifier, setIdentifier] = useState('')
    const [otp, setOtp] = useState('')
    const [devOtp, setDevOtp] = useState<string | null>(null)
    const [otpRequested, setOtpRequested] = useState(false)
    const [sessionError, setSessionError] = useState<string | null>(null)
    const [verifyingSession, setVerifyingSession] = useState(false)
    const [sessionVersion, setSessionVersion] = useState(0)
    const [activeTab, setActiveTab] = useState('dashboard')
    const sessionToken = getAdminAccessToken()
    const { isConnected, drivers, driverCount, alerts, demandHistory, demandIndex, avgWaitMinutes, dismissAlert, resolveAlert, escalateAlert } = useFleetData()
    const latestDemand = demandHistory[demandHistory.length - 1]?.trips ?? 0
    const previousDemand = demandHistory[demandHistory.length - 2]?.trips ?? latestDemand
    const demandDelta = latestDemand - previousDemand
    const demandDeltaLabel = `${demandDelta >= 0 ? '+' : ''}${demandDelta}`
    const avgDemand = demandHistory.length > 0
        ? Math.round(demandHistory.reduce((sum, p) => sum + p.trips, 0) / demandHistory.length)
        : 0

    const validateAndStoreToken = async () => {
        if (!tokenInput.trim()) {
            setSessionError('Enter a valid admin access token.')
            return
        }

        setVerifyingSession(true)
        setSessionError(null)
        try {
            setAdminAccessToken(tokenInput.trim())
            await fetchAdminMe()
            setTokenInput('')
            setSessionVersion((v) => v + 1)
        } catch (error: any) {
            clearAdminSession()
            setSessionError(error?.message ?? 'Invalid admin token')
        } finally {
            setVerifyingSession(false)
        }
    }

    const startOtpSession = async () => {
        if (!identifier.trim()) {
            setSessionError('Enter admin phone/email first.')
            return
        }

        setVerifyingSession(true)
        setSessionError(null)
        try {
            const result = await requestAdminOtp(identifier.trim()) as any
            setDevOtp(result?.devOtp ?? null)
            setOtpRequested(true)
        } catch (error: any) {
            setSessionError(error?.message ?? 'Failed to request OTP')
        } finally {
            setVerifyingSession(false)
        }
    }

    const verifyOtpSession = async () => {
        if (!identifier.trim() || otp.trim().length < 4) {
            setSessionError('Enter valid OTP.')
            return
        }

        setVerifyingSession(true)
        setSessionError(null)
        try {
            const session = await verifyAdminOtp(identifier.trim(), otp.trim())
            setAdminAccessToken(session.accessToken)
            await fetchAdminMe()
            setOtp('')
            setDevOtp(null)
            setOtpRequested(false)
            setSessionVersion((v) => v + 1)
        } catch (error: any) {
            clearAdminSession()
            setSessionError(error?.message ?? 'OTP verification failed')
        } finally {
            setVerifyingSession(false)
        }
    }

    if (!sessionToken) {
        return (
            <div className="admin-layout" key={sessionVersion}>
                <main className="main-content" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                    <div className="glass" style={{ width: 520, padding: 32, borderRadius: 20 }}>
                        <h2 style={{ marginBottom: 12 }}>Admin Session Required</h2>
                        <p style={{ color: 'var(--text-dim)', marginBottom: 20 }}>
                            Sign in with OTP or paste an access token to unlock dashboard, safety, and user operations.
                        </p>
                        <div className="search-container" style={{ marginBottom: 10 }}>
                            <input
                                type="text"
                                placeholder="Admin phone or email"
                                value={identifier}
                                onChange={(e) => setIdentifier(e.target.value)}
                            />
                        </div>
                        {!otpRequested ? (
                            <button className="action-btn" style={{ marginBottom: 12 }} onClick={startOtpSession} disabled={verifyingSession}>
                                {verifyingSession ? 'Requesting OTP...' : 'Request OTP'}
                            </button>
                        ) : (
                            <>
                                <div className="search-container" style={{ marginBottom: 10 }}>
                                    <input
                                        type="text"
                                        placeholder="Enter OTP"
                                        value={otp}
                                        onChange={(e) => setOtp(e.target.value)}
                                    />
                                </div>
                                {devOtp && (
                                    <p style={{ color: 'var(--text-dim)', marginBottom: 10 }}>Dev OTP: {devOtp}</p>
                                )}
                                <button className="action-btn" style={{ marginBottom: 12 }} onClick={verifyOtpSession} disabled={verifyingSession}>
                                    {verifyingSession ? 'Verifying OTP...' : 'Verify OTP'}
                                </button>
                            </>
                        )}
                        <p style={{ color: 'var(--text-dim)', marginBottom: 10 }}>or</p>
                        <div className="search-container" style={{ marginBottom: 14 }}>
                            <input
                                type="password"
                                placeholder="Admin access token"
                                value={tokenInput}
                                onChange={(e) => setTokenInput(e.target.value)}
                            />
                        </div>
                        {sessionError && (
                            <p style={{ color: 'var(--danger)', marginBottom: 12 }}>{sessionError}</p>
                        )}
                        <button className="action-btn" onClick={validateAndStoreToken} disabled={verifyingSession}>
                            {verifyingSession ? 'Verifying...' : 'Start Admin Session'}
                        </button>
                    </div>
                </main>
            </div>
        )
    }

    return (
        <div className="admin-layout" key={sessionVersion}>
            <aside className="sidebar glass">
                <div className="logo">
                    <Zap className="logo-icon" fill="var(--primary)" />
                    <span>VECTRA</span>
                </div>

                <nav>
                    <NavItem icon={<LayoutDashboard size={20} />} label="Command Center" active={activeTab === 'dashboard'} onClick={() => setActiveTab('dashboard')} />
                    <NavItem icon={<MapIcon size={20} />} label="Live Fleet" active={activeTab === 'fleet'} onClick={() => setActiveTab('fleet')} />
                    <NavItem icon={<Users size={20} />} label="User Ops" active={activeTab === 'users'} onClick={() => setActiveTab('users')} />
                    <NavItem icon={<List size={20} />} label="Trips" active={activeTab === 'trips'} onClick={() => setActiveTab('trips')} />
                    <NavItem icon={<Zap size={20} />} label="Incentives" active={activeTab === 'incentives'} onClick={() => setActiveTab('incentives')} />
                    <NavItem icon={<ShieldAlert size={20} />} label="Safety Hub" active={activeTab === 'safety'} onClick={() => setActiveTab('safety')} />
                    <NavItem icon={<BarChart3 size={20} />} label="Insights" active={activeTab === 'insights'} onClick={() => setActiveTab('insights')} />
                </nav>

                <div className="sidebar-footer">
                    <NavItem icon={<Settings size={20} />} label="Settings" onClick={() => { }} />
                </div>
            </aside>

            <main className="main-content">
                <header className="top-bar glass">
                    <div className="search-container">
                        <Search size={18} className="search-icon" />
                        <input type="text" placeholder="Search trips, drivers, users..." />
                    </div>
                    <div className="top-actions">
                        <div className={`status-badge ${isConnected ? 'connected pulse' : 'disconnected'}`}>
                            {isConnected ? <Wifi size={14} /> : <WifiOff size={14} />}
                            {isConnected ? 'Live' : 'Offline'}
                        </div>
                        {alerts.length > 0 && (
                            <div className="alert-badge">
                                <Bell size={20} />
                                <span>{alerts.length}</span>
                            </div>
                        )}
                        <div className="user-profile">
                            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Admin" alt="Admin" />
                        </div>
                        <button
                            className="action-btn"
                            onClick={() => {
                                clearAdminSession()
                                setSessionVersion((v) => v + 1)
                            }}
                        >
                            Logout
                        </button>
                    </div>
                </header>

                <section className="dashboard-content">
                    {activeTab === 'dashboard' && (
                        <DashboardView
                            demandHistory={demandHistory}
                            driverCount={driverCount}
                            alerts={alerts}
                            dismissAlert={dismissAlert}
                            demandIndex={demandIndex}
                            avgWaitMinutes={avgWaitMinutes}
                        />
                    )}
                    {activeTab === 'fleet' && <FleetMapView drivers={drivers} />}
                    {activeTab === 'safety' && <SafetyView alerts={alerts} resolveAlert={resolveAlert} escalateAlert={escalateAlert} />}
                    {activeTab === 'users' && <UserOpsView />}
                    {activeTab === 'trips' && <TripsView />}
                    {activeTab === 'incentives' && <IncentivesView />}
                    {activeTab === 'insights' && (
                        <div className="view-grid">
                            <div className="stat-cards">
                                <StatCard title="Current Demand" value={latestDemand} change={demandDeltaLabel} icon={<BarChart3 size={24} />} color="var(--primary)" />
                                <StatCard title="Avg Wait Time" value={`${avgWaitMinutes.toFixed(1)}m`} icon={<Zap size={24} />} color="var(--secondary)" />
                                <StatCard title="Average Demand" value={avgDemand} change={avgDemand >= latestDemand ? '+stable' : '-down'} icon={<Zap size={24} />} color="var(--secondary)" />
                                <StatCard title="Active Drivers" value={driverCount} change={`+${Math.max(0, driverCount - 1)}`} icon={<Navigation size={24} />} />
                                <StatCard title="Open Safety Alerts" value={alerts.length} change={alerts.length > 0 ? `+${alerts.length}` : '0'} icon={<ShieldAlert size={24} />} color="var(--accent)" />
                            </div>
                            <div className="chart-container glass">
                                <h3>Demand Trend</h3>
                                <ResponsiveContainer width="100%" height={280}>
                                    <LineChart data={demandHistory}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                                        <XAxis dataKey="time" tick={{ fill: 'var(--text-dim)', fontSize: 11 }} />
                                        <YAxis tick={{ fill: 'var(--text-dim)', fontSize: 11 }} />
                                        <Tooltip
                                            contentStyle={{ background: 'var(--bg-card)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8 }}
                                            labelStyle={{ color: 'var(--text-dim)' }}
                                        />
                                        <Line type="monotone" dataKey="trips" stroke="var(--primary)" strokeWidth={2} dot={false} />
                                    </LineChart>
                                </ResponsiveContainer>
                            </div>
                        </div>
                    )}
                </section>
            </main>
        </div>
    )
}

export default App
