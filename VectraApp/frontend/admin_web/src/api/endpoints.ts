import client from './client';

// ─── Auth ───
export const authApi = {
    login: (email: string, password: string) =>
        client.post('/auth/login', { email, password }),
    requestOtp: (channel: string, identifier: string) =>
        client.post('/auth/request-otp', { channel, identifier }),
    verifyOtp: (identifier: string, code: string) =>
        client.post('/auth/verify-otp', { identifier, code }),
    me: () => client.get('/auth/me'),
    refresh: (refreshToken: string) =>
        client.post('/auth/refresh', { refreshToken }),
    logout: () => client.post('/auth/logout'),
};

// ─── Admin ───
export const adminApi = {
    listUsers: () => client.get('/admin/users'),
    getUserDetails: (userId: string) => client.get(`/admin/users/${userId}`),
    suspendUser: (targetUserId: string, reason: string) =>
        client.post('/admin/users/suspend', { targetUserId, reason }),
    reinstateUser: (userId: string) =>
        client.post(`/admin/users/${userId}/reinstate`),
};

// ─── Drivers ───
export const driversApi = {
    getProfile: () => client.get('/drivers/profile'),
};

// ─── Trips ───
export const tripsApi = {
    getTrip: (id: string) => client.get(`/trips/${id}`),
};

// ─── Ride Requests ───
export const rideRequestsApi = {
    getCurrent: () => client.get('/ride-requests/current'),
};

// ─── Safety ───
export const safetyApi = {
    listIncidents: () => client.get('/safety/incidents'),
    getIncident: (id: string) => client.get(`/safety/incidents/${id}`),
    resolveIncident: (id: string, resolution: string) =>
        client.patch(`/safety/incidents/${id}/resolve`, { resolution }),
    reportIncident: (description: string, rideId?: string) =>
        client.post('/safety/incidents', { description, rideId }),
};
