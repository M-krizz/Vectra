import React from 'react';
import { NavLink, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
    LayoutDashboard,
    Users,
    MapPin,
    ShieldAlert,
    BarChart3,
    LogOut,
    Bell,
} from 'lucide-react';

const navItems = [
    { to: '/', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/users', label: 'User Management', icon: Users },
    { to: '/fleet', label: 'Fleet Monitor', icon: MapPin },
    { to: '/incidents', label: 'Safety & Incidents', icon: ShieldAlert },
    { to: '/analytics', label: 'Analytics', icon: BarChart3 },
];

const pageTitles: Record<string, string> = {
    '/': 'Dashboard',
    '/users': 'User Management',
    '/fleet': 'Fleet Monitoring',
    '/incidents': 'Safety & Incidents',
    '/analytics': 'Analytics & Reports',
};

const Layout: React.FC = () => {
    const { user, logout } = useAuth();
    const location = useLocation();

    const pageTitle =
        pageTitles[location.pathname] ||
        (location.pathname.startsWith('/users/') ? 'User Details' :
            location.pathname.startsWith('/incidents/') ? 'Incident Details' :
                'Vectra Admin');

    const initials = user?.fullName
        ? user.fullName.split(' ').map((w) => w[0]).join('').toUpperCase().slice(0, 2)
        : 'AD';

    return (
        <div className="app-layout">
            {/* Sidebar */}
            <aside className="sidebar">
                <div className="sidebar-brand">
                    <div className="sidebar-brand-icon">V</div>
                    <div className="sidebar-brand-text">
                        <h1>Vectra</h1>
                        <span>Admin Panel</span>
                    </div>
                </div>

                <nav className="sidebar-nav">
                    <div className="sidebar-section-label">Main Menu</div>
                    {navItems.map((item) => (
                        <NavLink
                            key={item.to}
                            to={item.to}
                            end={item.to === '/'}
                            className={({ isActive }) =>
                                `sidebar-link${isActive ? ' active' : ''}`
                            }
                        >
                            <item.icon />
                            <span>{item.label}</span>
                        </NavLink>
                    ))}

                    <div style={{ flex: 1 }} />

                    <div className="sidebar-section-label">Account</div>
                    <button className="sidebar-link" onClick={logout}>
                        <LogOut />
                        <span>Logout</span>
                    </button>
                </nav>
            </aside>

            {/* Main Content */}
            <div className="main-content">
                <header className="topbar">
                    <div className="topbar-left">
                        <h2>{pageTitle}</h2>
                    </div>
                    <div className="topbar-right">
                        <button className="topbar-btn" title="Notifications">
                            <Bell size={20} />
                            <span className="badge" />
                        </button>
                        <div className="topbar-avatar" title={user?.fullName || 'Admin'}>
                            {initials}
                        </div>
                    </div>
                </header>

                <main className="page-content">
                    <Outlet />
                </main>
            </div>
        </div>
    );
};

export default Layout;
