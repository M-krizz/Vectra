import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateEmergencyContactsTable1776000000000
  implements MigrationInterface
{
  name = 'CreateEmergencyContactsTable1776000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "emergency_contacts" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "phone_number" character varying NOT NULL,
        "relationship" character varying,
        "user_id" uuid NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_emergency_contacts" PRIMARY KEY ("id"),
        CONSTRAINT "FK_emergency_contacts_user_id" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_emergency_contacts_user_id"
      ON "emergency_contacts" ("user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_emergency_contacts_user_id"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "emergency_contacts"`);
  }
}