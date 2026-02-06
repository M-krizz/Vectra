import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnableExtensions1706652600000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS postgis;`);
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto;`);
  }

  public async down(_queryRunner: QueryRunner): Promise<void> {
    // Usually you don't drop extensions in down migrations in shared systems
  }
}
