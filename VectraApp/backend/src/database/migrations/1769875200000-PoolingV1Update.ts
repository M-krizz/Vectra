import { MigrationInterface, QueryRunner, Table, TableColumn, TableForeignKey } from "typeorm";

export class PoolingV1Update1769875200000 implements MigrationInterface {
    name = 'PoolingV1Update1769875200000';
    transaction = false; // Disable transaction for ALTER TYPE

    public async up(queryRunner: QueryRunner): Promise<void> {

        // 1. Create VehicleType Enum (if not exists)
        // PostgreSQL doesn't support IF NOT EXISTS for TYPE easily, so we can check or just catching error is messier.
        // Better pattern: Check if type exists before creating.
        const checkType = await queryRunner.query(`SELECT 1 FROM pg_type WHERE typname = 'vehicle_type_enum'`);
        if (checkType.length === 0) {
            await queryRunner.query(`CREATE TYPE "public"."vehicle_type_enum" AS ENUM('BIKE', 'AUTO', 'CAB')`);
        }

        // 2. Create PoolStatus Enum
        const checkPoolStatus = await queryRunner.query(`SELECT 1 FROM pg_type WHERE typname = 'pool_groups_status_enum'`);
        if (checkPoolStatus.length === 0) {
            await queryRunner.query(`CREATE TYPE "public"."pool_groups_status_enum" AS ENUM('FORMING', 'ACTIVE', 'COMPLETED', 'CANCELLED', 'EXPIRED')`);
        }

        // 3. Create pool_groups table
        await queryRunner.query(`
            CREATE TABLE "pool_groups" (
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

        // 4. Update ride_requests table
        // Add vehicle_type
        await queryRunner.query(`ALTER TABLE "ride_requests" ADD "vehicle_type" "public"."vehicle_type_enum" NOT NULL DEFAULT 'AUTO'`);

        // Add pool_group_id
        await queryRunner.query(`ALTER TABLE "ride_requests" ADD "pool_group_id" uuid`);

        // Update RideRequestStatus Enum to include 'POOLED'
        // This fails inside a transaction block usually.
        await queryRunner.query(`ALTER TYPE "public"."ride_requests_status_enum" ADD VALUE IF NOT EXISTS 'POOLED'`);

        // Add FK
        await queryRunner.query(`
            ALTER TABLE "ride_requests" 
            ADD CONSTRAINT "FK_ride_requests_pool_group_id" 
            FOREIGN KEY ("pool_group_id") REFERENCES "pool_groups"("id") ON DELETE SET NULL
        `);

    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "ride_requests" DROP CONSTRAINT "FK_ride_requests_pool_group_id"`);
        await queryRunner.query(`ALTER TABLE "ride_requests" DROP COLUMN "pool_group_id"`);
        await queryRunner.query(`ALTER TABLE "ride_requests" DROP COLUMN "vehicle_type"`);
        await queryRunner.query(`DROP TABLE "pool_groups"`);
        await queryRunner.query(`DROP TYPE "public"."pool_groups_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."vehicle_type_enum"`);
        // Cannot easily remove value from ENUM in Postgres
    }
}
