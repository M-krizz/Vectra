import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTripRiderPaymentStatus1773000000000 implements MigrationInterface {
  name = 'AddTripRiderPaymentStatus1773000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
          FROM pg_type
          WHERE typname = 'trip_riders_payment_status_enum'
        ) THEN
          CREATE TYPE "public"."trip_riders_payment_status_enum" AS ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED');
        END IF;
      END
      $$;
    `);

    await queryRunner.query(`
      ALTER TABLE "trip_riders"
      ADD COLUMN IF NOT EXISTS "payment_status" "public"."trip_riders_payment_status_enum" NOT NULL DEFAULT 'PENDING'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "trip_riders" DROP COLUMN IF EXISTS "payment_status"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."trip_riders_payment_status_enum"`);
  }
}
