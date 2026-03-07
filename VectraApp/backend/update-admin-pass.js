const { Client } = require('pg');
const bcrypt = require('bcrypt');

async function updatePassword() {
    const hash = await bcrypt.hash('password', 10);
    console.log('Generated new hash:', hash);

    const client = new Client({
        host: 'localhost',
        port: 5433,
        user: 'vectra',
        password: 'vectra_pass',
        database: 'vectra_db'
    });

    await client.connect();
    const res = await client.query("UPDATE users SET password_hash = $1, is_verified = true WHERE role = 'ADMIN' RETURNING id", [hash]);
    console.log('Update result:', res.rowCount, 'rows');

    await client.end();
}

updatePassword().catch(console.error);
