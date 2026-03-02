import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { getMe, logout as logoutApi, type MeResponse } from '../services/authService';

interface AuthContextType {
    user: MeResponse | null;
    loading: boolean;
    isAuthenticated: boolean;
    setToken: (token: string) => Promise<void>;
    logout: () => void;
    refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [user, setUser] = useState<MeResponse | null>(null);
    const [loading, setLoading] = useState(true);

    const refreshUser = useCallback(async () => {
        const token = localStorage.getItem('access_token');
        if (!token) {
            setUser(null);
            setLoading(false);
            return;
        }
        try {
            const me = await getMe();
            if (me.role !== 'ADMIN' && me.role !== 'COMMUNITY_ADMIN') {
                localStorage.removeItem('access_token');
                setUser(null);
            } else {
                setUser(me);
            }
        } catch {
            localStorage.removeItem('access_token');
            setUser(null);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        refreshUser();
    }, [refreshUser]);

    const setToken = async (token: string) => {
        localStorage.setItem('access_token', token);
        await refreshUser();
    };

    const logout = async () => {
        try {
            await logoutApi();
        } finally {
            setUser(null);
        }
    };

    return (
        <AuthContext.Provider
            value={{
                user,
                loading,
                isAuthenticated: !!user,
                setToken,
                logout,
                refreshUser,
            }}
        >
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be inside AuthProvider');
    return ctx;
}
