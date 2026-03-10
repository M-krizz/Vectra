import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateIncentivesTable1774000000000 implements MigrationInterface {
  name = 'CreateIncentivesTable1774000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "incentives" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "driver_user_id" uuid NOT NULL,
        "title" varchar(255) NOT NULL,
        "description" text NOT NULL DEFAULT '',
        "reward_amount" numeric(10,2) NOT NULL,
        "current_progress" int NOT NULL DEFAULT 0,
        "target_progress" int NOT NULL,
        "expires_at" timestamptz,
        "is_completed" boolean NOT NULL DEFAULT false,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "PK_incentives" PRIMARY KEY ("id"),
        CONSTRAINT "FK_incentives_driver" FOREIGN KEY ("driver_user_id")
          REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "IDX_incentives_driver_user_id"
      ON "incentives" ("driver_user_id")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_incentives_driver_user_id"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "incentives"`);
  }
}
