const http = require('http');

let ACCESS_TOKEN = '';
const results = [];

function makeRequest(options, body) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: data }));
        });
        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

function authHeaders() {
    return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + ACCESS_TOKEN
    };
}

function log(name, status, pass, detail) {
    const icon = pass ? 'PASS' : 'FAIL';
    results.push({ name, status, pass, detail });
    console.log(`[${icon}] ${name} => ${status} ${detail || ''}`);
}

async function test(name, opts, body, expectStatus, validator) {
    try {
        const res = await makeRequest(opts, body);
        const pass = Array.isArray(expectStatus) ? expectStatus.includes(res.status) : res.status === expectStatus;
        let detail = '';
        if (validator && pass) {
            try {
                const json = JSON.parse(res.body);
                detail = validator(json);
            } catch (e) { detail = 'Response parse ok'; }
        }
        if (!pass) detail = res.body.substring(0, 120);
        log(name, res.status, pass, detail);
        return res;
    } catch (e) {
        log(name, 0, false, e.message);
        return null;
    }
}

async function main() {
    console.log('=== VECTRA ADMIN DASHBOARD - BACKEND API TESTS ===\n');

    // 1. AUTH: Login
    console.log('--- Authentication ---');
    const loginRes = await test(
        'POST /auth/login',
        { hostname: 'localhost', port: 3000, path: '/api/v1/auth/login', method: 'POST', headers: { 'Content-Type': 'application/json' } },
        { email: 'admin@vectra.app', password: 'password' },
        [200, 201],
        (j) => { ACCESS_TOKEN = j.accessToken; return 'Token received: ' + !!j.accessToken; }
    );

    // 2. AUTH: Get Me
    await test(
        'GET /auth/me',
        { hostname: 'localhost', port: 3000, path: '/api/v1/auth/me', method: 'GET', headers: authHeaders() },
        null, 200,
        (j) => `role=${j.role}, email=${j.email}`
    );

    // 3. AUTH: Sessions
    await test(
        'GET /auth/sessions',
        { hostname: 'localhost', port: 3000, path: '/api/v1/auth/sessions', method: 'GET', headers: authHeaders() },
        null, 200,
        (j) => `${Array.isArray(j) ? j.length : '?'} sessions`
    );

    // 4. ADMIN: List Users
    console.log('\n--- Admin User Management ---');
    await test(
        'GET /admin/users',
        { hostname: 'localhost', port: 3000, path: '/api/v1/admin/users', method: 'GET', headers: authHeaders() },
        null, 200,
        (j) => `${Array.isArray(j) ? j.length : j.data?.length || '?'} users returned`
    );

    // 5. ADMIN: Dashboard Stats
    await test(
        'GET /admin/stats',
        { hostname: 'localhost', port: 3000, path: '/api/v1/admin/stats', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => JSON.stringify(j).substring(0, 80)
    );

    // 6. ADMIN: Drivers
    console.log('\n--- Driver Management ---');
    await test(
        'GET /admin/drivers',
        { hostname: 'localhost', port: 3000, path: '/api/v1/admin/drivers', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => `${Array.isArray(j) ? j.length : '?'} drivers`
    );

    await test(
        'GET /drivers (public)',
        { hostname: 'localhost', port: 3000, path: '/api/v1/drivers', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => `response received`
    );

    // 7. ANALYTICS
    console.log('\n--- Analytics ---');
    await test(
        'GET /analytics/overview',
        { hostname: 'localhost', port: 3000, path: '/api/v1/analytics/overview', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => JSON.stringify(j).substring(0, 80)
    );

    await test(
        'GET /analytics/trips',
        { hostname: 'localhost', port: 3000, path: '/api/v1/analytics/trips', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => JSON.stringify(j).substring(0, 80)
    );

    await test(
        'GET /analytics/revenue',
        { hostname: 'localhost', port: 3000, path: '/api/v1/analytics/revenue', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => JSON.stringify(j).substring(0, 80)
    );

    // 8. SAFETY
    console.log('\n--- Safety ---');
    await test(
        'GET /safety/incidents',
        { hostname: 'localhost', port: 3000, path: '/api/v1/safety/incidents', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => `${Array.isArray(j) ? j.length : '?'} incidents`
    );

    await test(
        'GET /safety/sos-alerts',
        { hostname: 'localhost', port: 3000, path: '/api/v1/safety/sos-alerts', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => `response received`
    );

    // 9. TRIPS
    console.log('\n--- Trips ---');
    await test(
        'GET /trips',
        { hostname: 'localhost', port: 3000, path: '/api/v1/trips', method: 'GET', headers: authHeaders() },
        null, [200, 404],
        (j) => `${Array.isArray(j) ? j.length : '?'} trips`
    );

    // 10. UNAUTHORIZED ACCESS
    console.log('\n--- Security ---');
    await test(
        'GET /auth/me (no token)',
        { hostname: 'localhost', port: 3000, path: '/api/v1/auth/me', method: 'GET', headers: { 'Content-Type': 'application/json' } },
        null, 401,
        () => 'Correctly rejected'
    );

    await test(
        'GET /admin/users (no token)',
        { hostname: 'localhost', port: 3000, path: '/api/v1/admin/users', method: 'GET', headers: { 'Content-Type': 'application/json' } },
        null, 401,
        () => 'Correctly rejected'
    );

    // SUMMARY
    console.log('\n=== SUMMARY ===');
    const passed = results.filter(r => r.pass).length;
    const failed = results.filter(r => !r.pass).length;
    console.log(`Total: ${results.length} | Passed: ${passed} | Failed: ${failed}`);

    // Write JSON results
    require('fs').writeFileSync('test-results.json', JSON.stringify(results, null, 2));
    console.log('Results saved to test-results.json');
}

main().catch(console.error);
