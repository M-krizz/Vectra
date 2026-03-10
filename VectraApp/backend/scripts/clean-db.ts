/**
 * Vectra DB Sanitization Script
 * ─────────────────────────────
 * Clears ALL transactional test data while preserving:
 *   - ADMIN users and their credentials
 *   - Driver & Rider user accounts
 *   - Driver profiles, vehicles, documents
 *   - Incentive configurations
 *   - Emergency contacts
 *   - Fast2SMS / SMTP configurationsData CLEARED:
 *   - ride_requests, trips, trip_riders, trip_events
 *   - pool_groups, messages, safety_incidents
 *   - driver_location_history, refresh_tokens
 *   - audit_logs (optional – pass --keep-audit to skip)
 *   - Redis: all transient keys (driver geo, sockets, locks)
 *
 * Usage:
 *   npx ts-node -r tsconfig-paths/register scripts/clean-db.ts
 *   npx ts-node -r tsconfig-paths/register scripts/clean-db.ts --keep-audit
 *   npx ts-node -r tsconfig-paths/register scripts/clean-db.ts --dry-run
 */

import 'dotenv/config';
import { DataSource } from 'typeorm';
import Redis from 'ioredis';

// ─── Config ───────────────────────────────────────────────────────────────────
const DRY_RUN = process.argv.includes('--dry-run');
const KEEP_AUDIT = process.argv.includes('--keep-audit');

// ─── Database ─────────────────────────────────────────────────────────────────
async function cleanDatabase(ds: DataSource): Promise<void> {
  const runner = ds.createQueryRunner();
  await runner.connect();
  await runner.startTransaction();

  try {
    console.log('\n📦  Cleaning transactional tables…');

    // Order matters → respect FK constraints (children first)
    const tables = [
      'trip_events',
      'trip_riders',
      'trips',
      'ride_requests',
      'pool_groups',
      'messages',
      'safety_incidents',
      'driver_location_history',
      'refresh_tokens',
    ];

    if (!KEEP_AUDIT) {
      tables.push('audit_logs');
    }

    for (const table of tables) {
      // Check the table exists before truncating
      const exists = await runner.query(
        `SELECT EXISTS (
           SELECT FROM information_schema.tables
           WHERE table_schema = 'public' AND table_name = $1
         )`,
        [table],
      );
      if (!exists[0].exists) {
        console.log(`  ⏭  ${table} — not found, skipping`);
        continue;
      }

      if (DRY_RUN) {
        const count = await runner.query(`SELECT COUNT(*) FROM "${table}"`);
        console.log(`  🔍 DRY-RUN ${table} → would delete ${count[0].count} rows`);
      } else {
        await runner.query(`TRUNCATE TABLE "${table}" CASCADE`);
        console.log(`  ✅  ${table} — truncated`);
      }
    }

    // Reset sequence on pool_groups if it uses serial (UUID doesn't need this)
    // Nothing to reset since all PKs are UUID gen_random_uuid()

    if (!DRY_RUN) {
      await runner.commitTransaction();
      console.log('\n✅  Database cleaned successfully.');
    } else {
      await runner.rollbackTransaction();
      console.log('\n🔍  DRY-RUN complete — no changes made.');
    }
  } catch (err) {
    await runner.rollbackTransaction();
    console.error('❌  Database cleanup failed:', err);
    throw err;
  } finally {
    await runner.release();
  }
}

// ─── Redis ────────────────────────────────────────────────────────────────────
async function cleanRedis(redis: Redis): Promise<void> {
  console.log('\n🗑️  Cleaning Redis transient keys…');

  const patterns = [
    'driver:location:*',
    'driver:socket:*',
    'socket:user:*',
    'trip:driver:*',
    'trip:otp:*:*',
    'lock:trip_accept:*',
    'pool:timeout:*',
  ];

  // Also clear the geospatial driver index
  const geoKey = 'drivers:geo';

  if (DRY_RUN) {
    for (const pattern of patterns) {
      const keys = await redis.keys(pattern);
      console.log(`  🔍 DRY-RUN "${pattern}" → ${keys.length} keys`);
    }
    const geoCount = await redis.zcard(geoKey);
    console.log(`  🔍 DRY-RUN "${geoKey}" → ${geoCount} members`);
    return;
  }

  let totalDeleted = 0;

  for (const pattern of patterns) {
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      const pipeline = redis.pipeline();
      keys.forEach((k) => pipeline.del(k));
      await pipeline.exec();
      totalDeleted += keys.length;
      console.log(`  ✅  Deleted ${keys.length} keys matching "${pattern}"`);
    }
  }

  await redis.del(geoKey);
  console.log(`  ✅  Cleared geospatial index "${geoKey}"`);

  console.log(`\n✅  Redis cleaned — ${totalDeleted} keys removed.`);
}

// ─── Verification ─────────────────────────────────────────────────────────────
async function verifySafeData(ds: DataSource): Promise<void> {
  console.log('\n🔐  Verifying preserved data…');

  const adminCount = await ds.query(
    `SELECT COUNT(*) FROM users WHERE role = 'ADMIN'`,
  );
  const driverCount = await ds.query(
    `SELECT COUNT(*) FROM users WHERE role = 'DRIVER'`,
  );
  const riderCount = await ds.query(
    `SELECT COUNT(*) FROM users WHERE role = 'RIDER'`,
  );

  console.log(`  👤  ADMIN  accounts : ${adminCount[0].count}`);
  console.log(`  🚗  DRIVER accounts : ${driverCount[0].count}`);
  console.log(`  🙋  RIDER  accounts : ${riderCount[0].count}`);

  if (Number(adminCount[0].count) === 0) {
    console.warn(
      '\n⚠️  WARNING: No ADMIN users found! Re-seed or create admin manually.',
    );
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('═══════════════════════════════════════════════');
  console.log(' 🧹  Vectra DB Sanitization');
  if (DRY_RUN) console.log(' 🔍  DRY-RUN mode — no changes will be made');
  if (KEEP_AUDIT) console.log(' 📋  Keeping audit_logs');
  console.log('═══════════════════════════════════════════════');

  // Connect to Postgres
  const ds = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 5432,
    username: process.env.DB_USERNAME || process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || process.env.DB_DATABASE || 'vectra',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });

  // Connect to Redis
  const redis = new Redis({
    host: process.env.REDIS_HOST || 'localhost',
    port: Number(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    lazyConnect: true,
  });

  try {
    await ds.initialize();
    console.log('\n✅  Connected to PostgreSQL');

    await redis.connect();
    console.log('✅  Connected to Redis');

    await cleanDatabase(ds);
    await cleanRedis(redis);
    await verifySafeData(ds);

    console.log('\n🎉  Sanitization complete — database is production-ready!\n');
  } catch (err) {
    console.error('\n❌  Fatal error during sanitization:', err);
    process.exit(1);
  } finally {
    await ds.destroy();
    redis.disconnect();
  }
}

main();
