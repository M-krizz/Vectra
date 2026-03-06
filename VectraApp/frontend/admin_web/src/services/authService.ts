import { post, get } from './api';

export interface LoginResponse {
    accessToken: string;
    refreshToken: string;
}

export interface MeResponse {
    id: string;
    email: string | null;
    phone: string | null;
    fullName: string | null;
    role: string;
    status: string;
}

export async function login(email: string, password: string): Promise<LoginResponse> {
    const data = await post<LoginResponse>('/api/v1/auth/login', { email, password });
    if (data.accessToken) {
        localStorage.setItem('access_token', data.accessToken);
    }
    return data;
}

export async function getMe(): Promise<MeResponse> {
    return get<MeResponse>('/api/v1/auth/me');
}

export async function logout(): Promise<void> {
    try {
        await post('/api/v1/auth/logout');
    } finally {
        localStorage.removeItem('access_token');
    }
}
