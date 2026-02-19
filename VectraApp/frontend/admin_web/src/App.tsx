import { useState, useEffect } from 'react'
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
    Navigation
} from 'lucide-react'
import './App.css'

function App() {
    const [activeTab, setActiveTab] = useState('dashboard')

    return (
        <div className="admin-layout">
            {/* Sidebar */}
            <aside className="sidebar glass">
                <div className="logo">
                    <Zap className="logo-icon" fill="var(--primary)" />
                    <span>VECTRA</span>
                </div>

                <nav>
                    <NavItem
                        icon={<LayoutDashboard size={20} />}
                        label="Command Center"
                        active={activeTab === 'dashboard'}
                        onClick={() => setActiveTab('dashboard')}
                    />
                    <NavItem
                        icon={<MapIcon size={20} />}
                        label="Live Fleet"
                        active={activeTab === 'fleet'}
                        onClick={() => setActiveTab('fleet')}
                    />
                    <NavItem
                        icon={<Users size={20} />}
                        label="User Ops"
                        active={activeTab === 'users'}
                        onClick={() => setActiveTab('users')}
                    />
                    <NavItem
                        icon={<ShieldAlert size={20} />}
                        label="Safety Hub"
                        active={activeTab === 'safety'}
                        onClick={() => setActiveTab('safety')}
                    />
                    <NavItem
                        icon={<BarChart3 size={20} />}
                        label="Insights"
                        active={activeTab === 'insights'}
                        onClick={() => setActiveTab('insights')}
                    />
                </nav>

                <div className="sidebar-footer">
                    <NavItem icon={<Settings size={20} />} label="Settings" onClick={() => { }} />
                </div>
            </aside>

            {/* Main Content */}
            <main className="main-content">
                <header className="top-bar glass">
                    <div className="search-container">
                        <Search size={18} className="search-icon" />
                        <input type="text" placeholder="Search trips, drivers, users..." />
                    </div>
                    <div className="top-actions">
                        <div className="status-badge pulse">
                            <span className="dot"></span>
                            Live Monitoring Active
                        </div>
                        <button className="icon-btn"><Bell size={20} /></button>
                        <div className="user-profile">
                            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Admin" alt="Admin" />
                        </div>
                    </div>
                </header>

                <section className="dashboard-content">
                    {activeTab === 'dashboard' && <DashboardView />}
                    {activeTab === 'fleet' && <FleetView />}
                    {activeTab === 'safety' && <SafetyView />}
                </section>
            </main>
        </div>
    )
}

function NavItem({ icon, label, active, onClick }: { icon: any, label: string, active?: boolean, onClick: () => void }) {
    return (
        <div className={`nav-item ${active ? 'active' : ''}`} onClick={onClick}>
            {icon}
            <span>{label}</span>
            {active && <div className="active-glow"></div>}
        </div>
    )
}

function DashboardView() {
    return (
        <div className="view-grid">
            <div className="stat-cards">
                <StatCard title="Active Trips" value="1,284" change="+12%" icon={<Navigation size={24} />} />
                <StatCard title="Total Revenue" value="₹4.2L" change="+8.4%" icon={<BarChart3 size={24} />} color="var(--primary)" />
                <StatCard title="Safety Incidents" value="2" change="-50%" icon={<ShieldAlert size={24} />} color="var(--accent)" />
                <StatCard title="Wait Time (Avg)" value="4.2m" change="-0.8m" icon={<Zap size={24} />} color="var(--secondary)" />
            </div>

            <div className="main-grid">
                <div className="chart-container glass">
                    <h3>Real-time Demand Index</h3>
                    <div className="mock-chart">
                        {/* Chart implementation goes here */}
                        <div className="chart-placeholder">Chart Visualization</div>
                    </div>
                </div>
                <div className="recent-activity glass">
                    <h3>Emergency Alerts</h3>
                    <div className="alert-item high-priority">
                        <ShieldAlert size={18} />
                        <div className="alert-info">
                            <p>SOS Triggered - Trip #RT8821</p>
                            <span>Driver: Ramesh | Rider: Vijay</span>
                        </div>
                        <button className="view-btn">Intercept</button>
                    </div>
                </div>
            </div>
        </div>
    )
}

function StatCard({ title, value, change, icon, color }: any) {
    return (
        <div className="stat-card glass" style={{ borderColor: color ? `${color}44` : '' }}>
            <div className="stat-icon" style={{ backgroundColor: color ? `${color}22` : '', color: color }}>
                {icon}
            </div>
            <div className="stat-body">
                <span className="stat-title">{title}</span>
                <h2 className="stat-value">{value}</h2>
                <span className="stat-change" style={{ color: change.startsWith('+') ? 'var(--success)' : 'var(--danger)' }}>
                    {change} <small>vs last hour</small>
                </span>
            </div>
        </div>
    )
}

function FleetView() {
    return (
        <div className="fleet-view">
            <h3>Live Fleet Monitoring</h3>
            <div className="map-placeholder glass">
                <MapIcon size={48} />
                <p>Interactive Command Map Loading...</p>
            </div>
        </div>
    )
}

function SafetyView() {
    return (
        <div className="safety-view glass">
            <h3>Incident Management</h3>
            <table>
                <thead>
                    <tr>
                        <th>Incident ID</th>
                        <th>Type</th>
                        <th>Status</th>
                        <th>Reported By</th>
                        <th>Time</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>#INC-991</td>
                        <td><span className="badge danger">SOS Alert</span></td>
                        <td><span className="dot open"></span> OPEN</td>
                        <td>Rider (Vijay)</td>
                        <td>2 mins ago</td>
                        <td><button className="action-btn">Manage</button></td>
                    </tr>
                </tbody>
            </table>
        </div>
    )
}

export default App
