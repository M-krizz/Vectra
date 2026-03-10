                                                                                            const ADMIN_ACCESS_TOKEN_KEY = 'vectra_admin_access_token';

export function setAdminAccessToken(token: string) {
    localStorage.setItem(ADMIN_ACCESS_TOKEN_KEY, token);
}

export function clearAdminSession() {
    localStorage.removeItem(ADMIN_ACCESS_TOKEN_KEY);
}

export function getAdminAccessToken(): string | null {
    const token = localStorage.getItem(ADMIN_ACCESS_TOKEN_KEY);
    return token && token.trim().length > 0 ? token : null;
}

export function requireAdminAccessToken(): string {
    const token = getAdminAccessToken();
    if (!token) {
        throw new Error('Admin session missing. Please sign in as admin.');
    }
    return token;
}

export function authHeadersOrThrow(contentType = true): HeadersInit {
    const token = requireAdminAccessToken();
    return {
        ...(contentType ? { 'Content-Type': 'application/json' } : {}),
        Authorization: `Bearer ${token}`,
    };
}
