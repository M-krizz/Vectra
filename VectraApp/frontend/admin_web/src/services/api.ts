const API_BASE = '';  // Vite proxy forwards /api → backend

interface FetchOptions {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
}

import { mockApiFetch } from './mockApi';

// ==========================================
// FEATURE FLAG: USE MOCK DATA INSTEAD OF REAL SERVER
const IS_MOCK_MODE = false;
// ==========================================

async function apiFetch<T = unknown>(path: string, opts: FetchOptions = {}): Promise<T> {
    if (IS_MOCK_MODE) {
        return mockApiFetch<T>(path, opts);
    }

    const token = localStorage.getItem('access_token');

    const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        ...(opts.headers || {}),
    };

    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(`${API_BASE}${path}`, {
        method: opts.method || 'GET',
        headers,
        body: opts.body ? JSON.stringify(opts.body) : undefined,
    });

    if (res.status === 401) {
        localStorage.removeItem('access_token');
        window.location.href = '/login';
        throw new Error('Unauthorized');
    }

    if (!res.ok) {
        const err = await res.json().catch(() => ({ message: res.statusText }));
        throw new Error(err.message || `HTTP ${res.status}`);
    }

    // handle empty response
    const text = await res.text();
    return text ? JSON.parse(text) : ({} as T);
}

export function get<T = unknown>(path: string) {
    return apiFetch<T>(path);
}

export function post<T = unknown>(path: string, body?: unknown) {
    return apiFetch<T>(path, { method: 'POST', body });
}

export function patch<T = unknown>(path: string, body?: unknown) {
    return apiFetch<T>(path, { method: 'PATCH', body });
}

export function del<T = unknown>(path: string) {
    return apiFetch<T>(path, { method: 'DELETE' });
}
