import { io, Socket } from 'socket.io-client';
import { clearAdminSession, requireAdminAccessToken } from './adminSession';

const SOCKET_URL = (import.meta as any).env.VITE_API_URL ?? 'http://localhost:3000';

let socket: Socket | null = null;

export function connectFleetSocket(): Socket {
    if (socket?.connected) return socket;

    const token = requireAdminAccessToken();

    socket = io(SOCKET_URL, {
        transports: ['websocket'],
        auth: { token },
        reconnectionAttempts: 8,
        reconnectionDelay: 2000,
    });

    socket.on('connect', () => {
        console.log('[Fleet] Connected:', socket!.id);
        socket!.emit('join_fleet');  // join admin:fleet room
    });

    socket.on('disconnect', () => console.warn('[Fleet] Disconnected'));

    socket.on('connect_error', (error: any) => {
        const message = (error?.message ?? '').toString().toLowerCase();
        if (message.includes('jwt') || message.includes('token') || message.includes('unauthorized')) {
            clearAdminSession();
            socket?.disconnect();
        }
    });

    return socket;
}

export function getSocket(): Socket | null {
    return socket;
}

export function disconnectFleetSocket() {
    socket?.disconnect();
    socket = null;
}
