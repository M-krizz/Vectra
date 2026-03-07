const { Client } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function seedAdmin() {
    console.log('Connecting to database...');
    const client = new Client({
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT || 5432),
        user: process.env.DB_USER || 'vectra',
        password: process.env.DB_PASS || 'vectra_pass',
        database: process.env.DB_NAME || 'vectra_db',
    });

    try {
        await client.connect();
        
        const email = 'admin@vectra.app';
        const password = 'admin';
        const hashedPassword = await bcrypt.hash(password, 10);
        
        console.log(`Checking if admin user ${email} exists...`);
        const res = await client.query('SELECT id FROM users WHERE email = $1', [email]);
        
        if (res.rowCount > 0) {
            console.log('Admin user already exists. Updating password to "admin"...');
            await client.query('UPDATE users SET password_hash = $1 WHERE email = $2', [hashedPassword, email]);
        } else {
            console.log('Creating new admin user...');
            await client.query(`
                INSERT INTO users (role, email, name, password_hash, status, is_verified) 
                VALUES ('ADMIN', $1, 'System Admin', $2, 'ACTIVE', true)
            `, [email, hashedPassword]);
        }
        
        console.log('✅ Admin user ready. Email: admin@vectra.app | Password: admin');
    } catch (err) {
        console.error('❌ Error seeding admin user:', err);
    } finally {
        await client.end();
    }
}

seedAdmin();
