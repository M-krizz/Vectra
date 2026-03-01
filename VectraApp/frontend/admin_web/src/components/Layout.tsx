import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Layout() {
    const { user, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = async () => {
        await logout();
        navigate('/login');
    };

    const initials = user?.fullName
        ? user.fullName
            .split(' ')
            .map((n) => n[0])
            .join('')
            .toUpperCase()
            .slice(0, 2)
        : 'AD';

    return (
        <div className="app-layout">
            {/* Sidebar */}
            <aside className="sidebar">
                <div className="sidebar-brand">
                    <div className="logo">V</div>
                    <h1>Vectra Admin</h1>
                </div>

                <nav className="sidebar-nav">
                    <NavLink to="/" end className={({ isActive }) => (isActive ? 'active' : '')}>
                        <span className="nav-icon">📊</span>
                        Dashboard
                    </NavLink>
                    <NavLink to="/users" className={({ isActive }) => (isActive ? 'active' : '')}>
                        <span className="nav-icon">👥</span>
                        Users
                    </NavLink>
                    <NavLink to="/trips" className={({ isActive }) => (isActive ? 'active' : '')}>
                        <span className="nav-icon">🚗</span>
                        Trips
                    </NavLink>
                    <NavLink to="/fleet" className={({ isActive }) => (isActive ? 'active' : '')}>
                        <span className="nav-icon">🌎</span>
                        Fleet Map
                    </NavLink>
                    <NavLink to="/safety" className={({ isActive }) => (isActive ? 'active' : '')}>
                        <span className="nav-icon">🛡️</span>
                        Safety &amp; Incidents
                    </NavLink>
                </nav>

                <div className="sidebar-footer">
                    <button className="btn btn-ghost" style={{ width: '100%' }} onClick={handleLogout}>
                        🚪 Logout
                    </button>
                </div>
            </aside>

            {/* Main */}
            <div className="main-content">
                <header className="top-header">
                    <h2>Admin Portal</h2>
                    <div className="header-actions">
                        <div className="header-user">
                            <div className="avatar">{initials}</div>
                            <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                                {user?.fullName || user?.email || 'Admin'}
                            </span>
                        </div>
                    </div>
                </header>

                <main className="page-content fade-in">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}
