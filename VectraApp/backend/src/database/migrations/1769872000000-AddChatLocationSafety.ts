import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddChatLocationSafety1769872000000 implements MigrationInterface {
  name = 'AddChatLocationSafety1769872000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create messages table for chat functionality
    await queryRunner.query(
      `CREATE TABLE "messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "ride_id" uuid NOT NULL,
        "sender_id" uuid NOT NULL,
        "content" text NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "PK_18325f38ae6de43878487eff986" PRIMARY KEY ("id")
      )`,
    );

    // Create safety incidents table
    await queryRunner.query(
      `CREATE TYPE "public"."safety_incidents_status_enum" AS ENUM('OPEN', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."safety_incidents_severity_enum" AS ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')`,
    );
    await queryRunner.query(
      `CREATE TABLE "safety_incidents" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "ride_id" uuid,
        "reported_by_id" uuid NOT NULL,
        "description" text NOT NULL,
        "status" "public"."safety_incidents_status_enum" NOT NULL DEFAULT 'OPEN',
        "severity" "public"."safety_incidents_severity_enum" NOT NULL DEFAULT 'MEDIUM',
        "resolution" text,
        "resolved_by_id" uuid,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "resolved_at" TIMESTAMP WITH TIME ZONE,
        CONSTRAINT "PK_d5f1e5a5b3c8e3f1e5a5b3c8e3f" PRIMARY KEY ("id")
      )`,
    );

    // Add foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "messages" ADD CONSTRAINT "FK_messages_ride_id" FOREIGN KEY ("ride_id") REFERENCES "ride_requests"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "messages" ADD CONSTRAINT "FK_messages_sender_id" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE`,
    );
    await queryRunner.query(
      `ALTER TABLE "safety_incidents" ADD CONSTRAINT "FK_safety_incidents_ride_id" FOREIGN KEY ("ride_id") REFERENCES "ride_requests"("id") ON DELETE SET NULL`,
    );
    await queryRunner.query(
      `ALTER TABLE "safety_incidents" ADD CONSTRAINT "FK_safety_incidents_reported_by_id" FOREIGN KEY ("reported_by_id") REFERENCES "users"("id") ON DELETE CASCADE`,
    );

    // Add indexes for performance
    await queryRunner.query(
      `CREATE INDEX "IDX_messages_ride_id" ON "messages" ("ride_id")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_messages_created_at" ON "messages" ("created_at")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_safety_incidents_status" ON "safety_incidents" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_safety_incidents_created_at" ON "safety_incidents" ("created_at")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop indexes
    await queryRunner.query(`DROP INDEX "IDX_safety_incidents_created_at"`);
    await queryRunner.query(`DROP INDEX "IDX_safety_incidents_status"`);
    await queryRunner.query(`DROP INDEX "IDX_messages_created_at"`);
    await queryRunner.query(`DROP INDEX "IDX_messages_ride_id"`);

    // Drop foreign key constraints
    await queryRunner.query(
      `ALTER TABLE "safety_incidents" DROP CONSTRAINT "FK_safety_incidents_reported_by_id"`,
    );
    await queryRunner.query(
      `ALTER TABLE "safety_incidents" DROP CONSTRAINT "FK_safety_incidents_ride_id"`,
    );
    await queryRunner.query(
      `ALTER TABLE "messages" DROP CONSTRAINT "FK_messages_sender_id"`,
    );
    await queryRunner.query(
      `ALTER TABLE "messages" DROP CONSTRAINT "FK_messages_ride_id"`,
    );

    // Drop tables
    await queryRunner.query(`DROP TABLE "safety_incidents"`);
    await queryRunner.query(`DROP TYPE "public"."safety_incidents_severity_enum"`);
    await queryRunner.query(`DROP TYPE "public"."safety_incidents_status_enum"`);
    await queryRunner.query(`DROP TABLE "messages"`);
  }
}