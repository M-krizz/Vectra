import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { authApi } from '../api/endpoints';

interface User {
    id: string;
    email: string | null;
    phone: string | null;
    fullName: string | null;
    role: string;
    status: string;
}

interface AuthState {
    user: User | null;
    token: string | null;
    loading: boolean;
    error: string | null;
    login: (email: string, password: string) => Promise<void>;
    logout: () => void;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<User | null>(() => {
        const stored = localStorage.getItem('vectra_admin_user');
        return stored ? JSON.parse(stored) : null;
    });
    const [token, setToken] = useState<string | null>(
        () => localStorage.getItem('vectra_admin_token'),
    );
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    // On mount, verify stored token
    useEffect(() => {
        if (token && !user) {
            authApi.me().then((res) => {
                setUser(res.data);
                localStorage.setItem('vectra_admin_user', JSON.stringify(res.data));
            }).catch(() => {
                setToken(null);
                setUser(null);
                localStorage.removeItem('vectra_admin_token');
                localStorage.removeItem('vectra_admin_user');
            });
        }
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    const login = useCallback(async (email: string, password: string) => {
        setLoading(true);
        setError(null);
        try {
            const res = await authApi.login(email, password);
            const { accessToken, user: userData } = res.data;

            // Ensure admin role
            if (userData.role !== 'ADMIN') {
                setError('Access denied. Admin role required.');
                setLoading(false);
                return;
            }

            localStorage.setItem('vectra_admin_token', accessToken);
            localStorage.setItem('vectra_admin_user', JSON.stringify(userData));
            setToken(accessToken);
            setUser(userData);
        } catch (err: any) {
            setError(err.response?.data?.message || 'Login failed. Please try again.');
        } finally {
            setLoading(false);
        }
    }, []);

    const logout = useCallback(() => {
        authApi.logout().catch(() => { });
        localStorage.removeItem('vectra_admin_token');
        localStorage.removeItem('vectra_admin_user');
        setToken(null);
        setUser(null);
    }, []);

    return (
        <AuthContext.Provider value={{ user, token, loading, error, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = (): AuthState => {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used within AuthProvider');
    return ctx;
};
