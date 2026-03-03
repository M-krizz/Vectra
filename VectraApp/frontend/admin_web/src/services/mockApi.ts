import { Trip } from './tripService';
import { User, DriverProfile, UserDetails } from './userService';
import { Incident } from './safetyService';

const MOCK_TOKEN = 'mock-jwt-token-777';

const MOCK_USERS: User[] = [
    {
        id: 'u1', email: 'admin@vectra.app', phone: null, fullName: 'Vectra Admin',
        role: 'ADMIN', status: 'ACTIVE', isVerified: true, isSuspended: false,
        suspensionReason: null, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(), lastLoginAt: new Date().toISOString()
    },
    {
        id: 'u2', email: 'driver1@mock.app', phone: '+1234567890', fullName: 'John Driver',
        role: 'DRIVER', status: 'ACTIVE', isVerified: true, isSuspended: false,
        suspensionReason: null, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(), lastLoginAt: new Date().toISOString()
    },
    {
        id: 'u3', email: 'rider1@mock.app', phone: '+0987654321', fullName: 'Alice Rider',
        role: 'RIDER', status: 'ACTIVE', isVerified: true, isSuspended: false,
        suspensionReason: null, isActive: true, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(), lastLoginAt: new Date().toISOString()
    }
];

const MOCK_DRIVERS: Record<string, DriverProfile> = {
    'u2': {
        userId: 'u2', verificationStatus: 'VERIFIED', ratingAvg: 4.8,
        ratingCount: 152, completionRate: 98, onlineStatus: true
    }
};

const MOCK_INCIDENTS: Incident[] = [
    {
        id: 'inc1', reportedById: 'u3', description: 'Driver was speeding heavily',
        status: 'OPEN', resolution: null, resolvedById: null,
        createdAt: new Date().toISOString(), updatedAt: new Date().toISOString()
    }
];

const MOCK_API_INTERCEPTOR: Record<string, any> = {
    'POST:/api/v1/auth/login': (req: any) => {
        return { accessToken: MOCK_TOKEN, refreshToken: 'mock-refresh' };
    },
    'GET:/api/v1/auth/me': () => {
        return MOCK_USERS[0];
    },
    'POST:/api/v1/auth/logout': () => {
        return { success: true };
    },
    'GET:/api/v1/admin/users': () => {
        return MOCK_USERS;
    },
    'POST:/api/v1/admin/users/suspend': (req: any) => {
        const body = JSON.parse(req.body);
        const u = MOCK_USERS.find(x => x.id === body.targetUserId);
        if (u) {
            u.isSuspended = true;
            u.status = 'SUSPENDED';
            u.suspensionReason = body.reason;
        }
        return { success: true };
    },
    'GET:/api/v1/safety/incidents': () => {
        return MOCK_INCIDENTS;
    }
};

export const IS_MOCK_MODE = true;

export async function mockApiFetch<T>(path: string, opts: any): Promise<T> {
    const method = opts.method || 'GET';
    const key = `${method}:${path}`;

    // Exact match
    if (MOCK_API_INTERCEPTOR[key]) {
        console.log(`[MOCK] Intercepted ${key}`);
        return new Promise(res => setTimeout(() => res(MOCK_API_INTERCEPTOR[key](opts)), 300));
    }

    // Pattern matches
    if (method === 'GET' && path.startsWith('/api/v1/admin/users/')) {
        const id = path.split('/').pop();
        const user = MOCK_USERS.find(u => u.id === id);
        return new Promise(res => setTimeout(() => res({ user, driverProfile: MOCK_DRIVERS[id!] || null } as any), 300));
    }

    if (method === 'POST' && path.match(/\/api\/v1\/admin\/users\/.*\/reinstate/)) {
        const id = path.split('/')[5];
        const u = MOCK_USERS.find(x => x.id === id);
        if (u) { u.isSuspended = false; u.status = 'ACTIVE'; }
        return new Promise(res => setTimeout(() => res({ success: true } as any), 300));
    }

    if (method === 'PATCH' && path.match(/\/api\/v1\/safety\/incidents\/.*\/resolve/)) {
        const id = path.split('/')[5];
        const inc = MOCK_INCIDENTS.find(x => x.id === id);
        if (inc) { inc.status = 'RESOLVED'; inc.resolution = JSON.parse(opts.body).resolution; }
        return new Promise(res => setTimeout(() => res({ success: true } as any), 300));
    }

    if (method === 'GET' && path.startsWith('/api/v1/trips/')) {
        const id = path.split('/').pop();
        const trip: Trip = {
            id: id || 'test-trip-id',
            driverUserId: 'u2',
            status: 'IN_PROGRESS',
            assignedAt: new Date().toISOString(),
            startAt: new Date().toISOString(),
            endAt: null,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };
        // Mock a 404 if "error" in ID
        if (id?.includes('error')) {
            return Promise.reject(new Error('Trip not found'));
        }
        return new Promise(res => setTimeout(() => res(trip as any), 300));
    }

    console.warn(`[MOCK] Unhandled API Call: ${key}`);
    return Promise.reject(new Error('Mock Not Implemented'));
}
