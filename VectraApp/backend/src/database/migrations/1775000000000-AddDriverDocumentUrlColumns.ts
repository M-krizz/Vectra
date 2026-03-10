import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDriverDocumentUrlColumns1775000000000
  implements MigrationInterface
{
  name = 'AddDriverDocumentUrlColumns1775000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "driver_profiles"
      ADD COLUMN IF NOT EXISTS "license_file_url" character varying
    `);

    await queryRunner.query(`
      ALTER TABLE "driver_profiles"
      ADD COLUMN IF NOT EXISTS "rc_file_url" character varying
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "driver_profiles"
      DROP COLUMN IF EXISTS "rc_file_url"
    `);

    await queryRunner.query(`
      ALTER TABLE "driver_profiles"
      DROP COLUMN IF EXISTS "license_file_url"
    `);
  }
}