const http = require('http');

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

async function main() {
    // Step 1: Login
    const loginRes = await makeRequest({
        hostname: 'localhost', port: 3000, path: '/api/v1/auth/login',
        method: 'POST', headers: { 'Content-Type': 'application/json' }
    }, { email: 'admin@vectra.app', password: 'password' });

    console.log('LOGIN:', loginRes.status);
    if (loginRes.status >= 400) {
        console.log('FAIL:', loginRes.body);
        return;
    }

    const tokens = JSON.parse(loginRes.body);
    console.log('TOKEN_OK:', !!tokens.accessToken);

    // Step 2: /me
    const meRes = await makeRequest({
        hostname: 'localhost', port: 3000, path: '/api/v1/auth/me',
        method: 'GET', headers: { 'Authorization': 'Bearer ' + tokens.accessToken }
    });

    console.log('ME:', meRes.status);
    if (meRes.status >= 400) {
        console.log('ME_FAIL:', meRes.body);
    } else {
        const me = JSON.parse(meRes.body);
        console.log('ROLE:', me.role);
        console.log('EMAIL:', me.email);
    }
}

main().catch(console.error);
