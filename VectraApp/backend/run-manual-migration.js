const { DataSource } = require('typeorm');
require('dotenv').config();

const AppDataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    username: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    entities: [],
    synchronize: false,
    migrations: [],
});

async function runMigration() {
    try {
        await AppDataSource.initialize();
        console.log("Data Source has been initialized!");

        const queryRunner = AppDataSource.createQueryRunner();
        await queryRunner.connect();

        // No transaction block because ENUM updates fail inside them sometimes

        console.log('Running Pooling Migration...');

        // 1. Vehicle Type
        try {
            await queryRunner.query(`ALTER TYPE "public"."ride_requests_status_enum" ADD VALUE IF NOT EXISTS 'POOLED'`);
            console.log('Updated ride_requests_status_enum');
        } catch (e) { console.error('Error updating status enum:', e); }

        try {
            await queryRunner.query(`DO $$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vehicle_type_enum') THEN
                    CREATE TYPE "public"."vehicle_type_enum" AS ENUM('BIKE', 'AUTO', 'CAB');
                END IF;
            END $$;`);
            console.log('Created vehicle_type_enum');
        } catch (e) { console.error('Error creating vehicle_type_enum:', e); }

        try {
            await queryRunner.query(`DO $$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pool_groups_status_enum') THEN
                    CREATE TYPE "public"."pool_groups_status_enum" AS ENUM('FORMING', 'ACTIVE', 'COMPLETED', 'CANCELLED', 'EXPIRED');
                END IF;
            END $$;`);
            console.log('Created pool_groups_status_enum');
        } catch (e) { console.error('Error creating pool_groups_status_enum:', e); }

        try {
            await queryRunner.query(`
                CREATE TABLE IF NOT EXISTS "pool_groups" (
                    "id" uuid NOT NULL DEFAULT uuid_generate_v4(), 
                    "status" "public"."pool_groups_status_enum" NOT NULL DEFAULT 'FORMING', 
                    "vehicle_type" "public"."vehicle_type_enum" NOT NULL, 
                    "current_riders_count" integer NOT NULL DEFAULT 0, 
                    "max_riders" integer NOT NULL DEFAULT 3, 
                    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), 
                    "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), 
                    CONSTRAINT "PK_pool_groups_id" PRIMARY KEY ("id")
                )
            `);
            console.log('Created pool_groups table');
        } catch (e) { console.error('Error creating pool_groups table:', e); }

        try {
            // Check column existence before adding
            await queryRunner.query(`ALTER TABLE "ride_requests" ADD COLUMN IF NOT EXISTS "vehicle_type" "public"."vehicle_type_enum" NOT NULL DEFAULT 'AUTO'`);
            console.log('Added vehicle_type column');
        } catch (e) { console.error('Error adding vehicle_type:', e); }

        try {
            await queryRunner.query(`ALTER TABLE "ride_requests" ADD COLUMN IF NOT EXISTS "pool_group_id" uuid`);
            console.log('Added pool_group_id column');
        } catch (e) { console.error('Error adding pool_group_id:', e); }

        try {
            await queryRunner.query(`
                DO $$ BEGIN
                    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_ride_requests_pool_group_id') THEN
                        ALTER TABLE "ride_requests" 
                        ADD CONSTRAINT "FK_ride_requests_pool_group_id" 
                        FOREIGN KEY ("pool_group_id") REFERENCES "pool_groups"("id") ON DELETE SET NULL;
                    END IF;
                END $$;
            `);
            console.log('Added FK constraint');
        } catch (e) { console.error('Error adding FK:', e); }

        await queryRunner.release();
        await AppDataSource.destroy();
        console.log('Migration Completed.');

    } catch (err) {
        console.error("Error during migration execution:", err);
    }
}

runMigration();
