const { Client } = require('pg');
const io = require('socket.io-client');

const BASE_URL = 'http://localhost:3000/api/v1';
const SOCKET_URL = 'http://localhost:3000';

async function verifyAllUsersInDB() {
    const client = new Client({
        host: 'localhost',
        port: 5432,
        user: 'postgres',
        password: '8Characters@123',
        database: 'vectra_db',
    });
    await client.connect();
    await client.query("UPDATE users SET is_verified = true");
    await client.query("UPDATE driver_profiles SET status = 'VERIFIED'");
    await client.end();
    console.log('Database updated: all users and drivers are now verified.');
}

async function request(method, path, body, token) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(BASE_URL + path, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
    });

    const text = await res.text();
    let data;
    try { data = JSON.parse(text); } catch (e) { data = text; }

    if (!res.ok) {
        throw { status: res.status, data };
    }
    return data;
}

async function run() {
    console.log('--- Vectra E2E Simulation ---');
    try {
        console.log('1. Registering Rider...');
        let riderToken;
        try {
            const auth = await request('POST', '/auth/login', { email: 'test.rider@vectra.com', password: 'SecurePassword123!' });
            riderToken = auth.accessToken;
        } catch (e) {
            if (e.status === 401 || e.status === 404) {
                const payload = {
                    fullName: 'Test Rider', email: 'test.rider@vectra.com', phone: '+1111111111', password: 'SecurePassword123!'
                };
                const auth = await request('POST', '/auth/register/rider', payload).catch(err => {
                    console.error("Rider Registration failed", err);
                    throw err;
                });
                riderToken = auth.accessToken;
            } else throw e;
        }
        console.log('Rider authenticated.');

        console.log('2. Registering Driver...');
        let driverToken;
        try {
            const payload = {
                fullName: 'Test Driver', email: 'test.driver@vectra.com', phone: '+2222222222', password: 'SecurePassword123!',
                licenseNumber: 'DL123', licenseState: 'CA'
            };
            // Try to register, ignore if already exists (400 or 409 etc)
            await request('POST', '/auth/register/driver', payload).catch(err => { console.log('Driver might already exist'); });

            // Enforce DB verification
            await verifyAllUsersInDB();

            const login = await request('POST', '/auth/login', { email: 'test.driver@vectra.com', password: 'SecurePassword123!' });
            driverToken = login.accessToken;
        } catch (e) {
            console.error("Driver Auth failed", e);
            throw e;
        }
        console.log('Driver authenticated.');

        console.log('3. Connecting Sockets...');
        const riderSocket = io(SOCKET_URL, { transports: ['websocket'], auth: { token: riderToken } });
        const driverDefaultSocket = io(SOCKET_URL, { transports: ['websocket'], auth: { token: driverToken } });

        const receivedEvents = [];

        riderSocket.on('connect', () => console.log('Rider socket connected'));
        driverDefaultSocket.on('connect', () => console.log('Driver socket connected'));

        riderSocket.on('trip_status', (data) => {
            console.log('Rider received trip_status:', data);
            receivedEvents.push('rider:trip_status:' + data.status);
        });

        riderSocket.on('location_update', (data) => {
            console.log('Rider received location_update:', data);
            receivedEvents.push('rider:location_update');
        });

        driverDefaultSocket.on('trip_status', (data) => {
            console.log('Driver received trip_status:', data);
            receivedEvents.push('driver:trip_status:' + data.status);
        });

        await new Promise(r => setTimeout(r, 1000)); // wait for socket connection

        console.log('4. Driver goes online...');
        await request('POST', '/drivers/online', { online: true }, driverToken).catch(err => {
            console.log("Error going online:", err.status, err.data);
        });

        console.log('5. Rider requests ride...');
        const rideRequest = await request('POST', '/ride-requests', {
            pickupPoint: { type: 'Point', coordinates: [77.5946, 12.9716] },
            dropPoint: { type: 'Point', coordinates: [77.6245, 12.9352] },
            pickupAddress: 'MG Road', dropAddress: 'Koramangala',
            rideType: 'SOLO', vehicleType: 'AUTO'
        }, riderToken).catch(err => {
            console.error("Error creating request:", err);
            throw err;
        });
        console.log('Ride Request Created:', rideRequest.id);

        console.log('6. Driver attempts to accept ride...');
        let tripId;
        try {
            const acceptRes = await request('POST', `/ride-requests/${rideRequest.id}/accept`, {}, driverToken);
            console.log('Ride accepted:', acceptRes);
            tripId = acceptRes.id;
            // Both join the trip room
            riderSocket.emit('join_trip_room', { tripId });
            driverDefaultSocket.emit('join_trip_room', { tripId });
            await new Promise(r => setTimeout(r, 500)); // Wait for join to process
        } catch (e) {
            console.error('Failed to accept ride. Details:', e.status || e, e.data || '');
            process.exit(1);
        }

        console.log('7. Driver starts trip...');
        try {
            const startRes = await request('PATCH', `/trips/${tripId}/start`, {}, driverToken);
            console.log('Trip started:', startRes.status);
        } catch (e) {
            console.error('Failed to start trip:', e.status, e.data);
            process.exit(1);
        }

        console.log('7.5. Driver sends location update...');
        // Based on TripsController, it's a PATCH to /trips/:id/location
        try {
            await request('PATCH', `/trips/${tripId}/location`, { lat: 12.94, lng: 77.61 }, driverToken);
            console.log('Location update sent.');
            await new Promise(r => setTimeout(r, 1000)); // wait for socket event
        } catch (e) {
            console.error('Failed to send location update:', e.status, e.data);
        }

        console.log('8. Driver completes trip...');
        try {
            const completeRes = await request('PATCH', `/trips/${tripId}/complete`, {}, driverToken);
            console.log('Trip completed:', completeRes.status);
            await new Promise(r => setTimeout(r, 1000)); // wait for socket event
        } catch (e) {
            console.error('Failed to complete trip:', e.status, e.data);
            process.exit(1);
        }

        console.log('--- Socket Events Received ---');
        console.log(receivedEvents);

        process.exit(0);
    } catch (e) {
        console.error('Simulation Failed:', e);
        process.exit(1);
    }
}

run();
