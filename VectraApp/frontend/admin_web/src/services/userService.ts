import { get, post } from './api';

export interface User {
    id: string;
    email: string | null;
    phone: string | null;
    fullName: string | null;
    role: string;
    status: string;
    isVerified: boolean;
    isSuspended: boolean;
    suspensionReason: string | null;
    isActive: boolean;
    createdAt: string;
    updatedAt: string;
    lastLoginAt: string | null;
}

export interface DriverProfile {
    userId: string;
    verificationStatus: string;
    ratingAvg: number;
    ratingCount: number;
    completionRate: number;
    onlineStatus: boolean;
}

export interface UserDetails {
    user: User;
    driverProfile: DriverProfile | null;
}

export function listUsers(): Promise<User[]> {
    return get<User[]>('/api/v1/admin/users');
}

export function getUserDetails(userId: string): Promise<UserDetails> {
    return get<UserDetails>(`/api/v1/admin/users/${userId}`);
}

export function suspendUser(targetUserId: string, reason?: string) {
    return post('/api/v1/admin/users/suspend', { targetUserId, reason });
}

export function reinstateUser(userId: string) {
    return post(`/api/v1/admin/users/${userId}/reinstate`);
}
