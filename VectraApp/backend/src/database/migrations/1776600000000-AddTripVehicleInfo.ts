import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Adds vehicle_type, ride_type, and distance_meters to the trips table.
 * These allow the MatchingService to filter drivers by vehicle type,
 * and the TripsService to calculate the correct fare on completion.
 */
export class AddTripVehicleInfo1776600000000 implements MigrationInterface {
  name = 'AddTripVehicleInfo1776600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Re-use the existing vehicle_type enum from ride_requests
    await queryRunner.query(`
      ALTER TABLE trips
        ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(20),
        ADD COLUMN IF NOT EXISTS ride_type    VARCHAR(10),
        ADD COLUMN IF NOT EXISTS distance_meters INT
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE trips
        DROP COLUMN IF EXISTS vehicle_type,
        DROP COLUMN IF EXISTS ride_type,
        DROP COLUMN IF EXISTS distance_meters
    `);
  }
}
