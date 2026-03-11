import { MigrationInterface, QueryRunner } from 'typeorm';

export class RemovePasswordHash1772000000000 implements MigrationInterface {
    name = 'RemovePasswordHash1772000000000';

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Drop password_hash column from users table
        await queryRunner.query(`
      ALTER TABLE "users" DROP COLUMN IF EXISTS "password_hash"
    `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Restore password_hash column (for rollback only)
        await queryRunner.query(`
      ALTER TABLE "users" ADD COLUMN "password_hash" text NULL
    `);
    }
}
