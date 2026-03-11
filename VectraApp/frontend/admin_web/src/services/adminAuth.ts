import { authHeadersOrThrow } from './adminSession';

const API_URL = (import.meta as any).env.VITE_API_URL ?? 'http://localhost:3000';

export interface AuthMeResponse {
    id: string;
    role: string;
    email?: string | null;
    phone?: string | null;
    fullName?: string | null;
}

export async function fetchAdminMe(): Promise<AuthMeResponse> {
    const response = await fetch(`${API_URL}/api/v1/auth/me`, {
        headers: authHeadersOrThrow(false),
    });

    if (!response.ok) {
        throw new Error(`Session check failed (${response.status})`);
    }

    const me = await response.json() as AuthMeResponse;
    if (me.role !== 'ADMIN') {
        throw new Error('Current session is not an admin account.');
    }

    return me;
}

export async function requestAdminOtp(identifier: string) {
    const channel = identifier.includes('@') ? 'email' : 'phone';

    const response = await fetch(`${API_URL}/api/v1/auth/request-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ channel, identifier }),
    });

    if (!response.ok) {
        throw new Error(`OTP request failed (${response.status})`);
    }

    return response.json();
}

export async function verifyAdminOtp(identifier: string, code: string) {
    const response = await fetch(`${API_URL}/api/v1/auth/verify-otp`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-role-hint': 'ADMIN',
        },
        body: JSON.stringify({ identifier, code }),
    });

    if (!response.ok) {
        throw new Error(`OTP verification failed (${response.status})`);
    }

    return response.json() as Promise<{
        accessToken: string;
        refreshToken: string;
        refreshTokenId: string;
    }>;
}
