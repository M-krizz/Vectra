import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDriverLocationHistory1769815727647 implements MigrationInterface {
  name = 'AddDriverLocationHistory1769815727647';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX "public"."IDX_a48b6399c9111fe3c54ee9b3ab"`,
    );
    await queryRunner.query(
      `CREATE TABLE "driver_location_history" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "driver_user_id" uuid NOT NULL, "point" geography(Point,4326) NOT NULL, "speed_kph" numeric(5,2), "heading" numeric(5,2), "accuracy" numeric(5,2), "recorded_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_22cdcf969e7546a70deff6be5b7" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_driver_location_history_point_gist" ON "driver_location_history" USING GiST ("point") `,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_ride_requests_pickup_gist" ON "ride_requests" USING GiST ("pickup_point") `,
    );
    await queryRunner.query(
      `CREATE INDEX "idx_ride_requests_drop_gist" ON "ride_requests" USING GiST ("drop_point") `,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_location_history" ADD CONSTRAINT "FK_d5941664f1196dc07887df879a3" FOREIGN KEY ("driver_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "driver_location_history" DROP CONSTRAINT "FK_d5941664f1196dc07887df879a3"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."idx_ride_requests_drop_gist"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."idx_ride_requests_pickup_gist"`,
    );
    await queryRunner.query(
      `DROP INDEX "public"."idx_driver_location_history_point_gist"`,
    );
    await queryRunner.query(`DROP TABLE "driver_location_history"`);
    await queryRunner.query(
      `CREATE INDEX "IDX_a48b6399c9111fe3c54ee9b3ab" ON "ride_requests" USING GiST ("pickup_point") `,
    );
  }
}
