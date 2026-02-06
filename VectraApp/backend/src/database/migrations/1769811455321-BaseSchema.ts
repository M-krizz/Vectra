import { MigrationInterface, QueryRunner } from 'typeorm';

export class BaseSchema1769811455321 implements MigrationInterface {
  name = 'BaseSchema1769811455321';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TYPE "public"."driver_profiles_verification_status_enum" AS ENUM('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED')`,
    );
    await queryRunner.query(
      `CREATE TABLE "driver_profiles" ("user_id" uuid NOT NULL, "verification_status" "public"."driver_profiles_verification_status_enum" NOT NULL DEFAULT 'PENDING', "rating_avg" numeric(3,2) NOT NULL DEFAULT '0', "rating_count" integer NOT NULL DEFAULT '0', "completion_rate" numeric(5,2) NOT NULL DEFAULT '0', "online_status" boolean NOT NULL DEFAULT false, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_cec43742cd6dea0e8fcae3e29d8" PRIMARY KEY ("user_id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."ride_requests_ride_type_enum" AS ENUM('SOLO', 'POOL')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."ride_requests_status_enum" AS ENUM('REQUESTED', 'MATCHING', 'EXPIRED', 'CANCELLED')`,
    );
    await queryRunner.query(
      `CREATE TABLE "ride_requests" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "rider_user_id" uuid NOT NULL, "pickup_point" geography(Point,4326) NOT NULL, "drop_point" geography(Point,4326) NOT NULL, "pickup_address" text, "drop_address" text, "ride_type" "public"."ride_requests_ride_type_enum" NOT NULL, "status" "public"."ride_requests_status_enum" NOT NULL DEFAULT 'REQUESTED', "requested_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "expires_at" TIMESTAMP WITH TIME ZONE, CONSTRAINT "PK_92c563a19918f0e48a844c143a9" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_a48b6399c9111fe3c54ee9b3ab" ON "ride_requests" USING GiST ("pickup_point") `,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."trip_riders_status_enum" AS ENUM('JOINED', 'CANCELLED', 'NO_SHOW')`,
    );
    await queryRunner.query(
      `CREATE TABLE "trip_riders" ("trip_id" uuid NOT NULL, "rider_user_id" uuid NOT NULL, "pickup_point" geography(Point,4326) NOT NULL, "drop_point" geography(Point,4326) NOT NULL, "pickup_sequence" integer, "drop_sequence" integer, "fare_share" numeric(10,2), "status" "public"."trip_riders_status_enum" NOT NULL DEFAULT 'JOINED', CONSTRAINT "PK_3b6117cc140d0828d145d2d8a4e" PRIMARY KEY ("trip_id", "rider_user_id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "trip_events" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "trip_id" uuid NOT NULL, "event_type" text NOT NULL, "old_value" text, "new_value" text, "metadata" jsonb, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_df6ea3b2ad6f86f525d796220da" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."trips_status_enum" AS ENUM('REQUESTED', 'ASSIGNED', 'ARRIVING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')`,
    );
    await queryRunner.query(
      `CREATE TABLE "trips" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "driver_user_id" uuid, "status" "public"."trips_status_enum" NOT NULL DEFAULT 'REQUESTED', "assigned_at" TIMESTAMP WITH TIME ZONE, "start_at" TIMESTAMP WITH TIME ZONE, "end_at" TIMESTAMP WITH TIME ZONE, "current_route_polyline" text, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_f71c231dee9c05a9522f9e840f5" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "audit_logs" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "actor_user_id" uuid, "target_user_id" uuid, "action_type" text NOT NULL, "reason" text, "metadata" jsonb, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_1bb179d048bbc581caa3b013439" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "vehicles" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "driver_user_id" uuid NOT NULL, "vehicle_type" text NOT NULL, "make" text, "model" text, "plate_number" text NOT NULL, "seating_capacity" integer NOT NULL, "emission_factor_g_per_km" numeric(10,2), "is_active" boolean NOT NULL DEFAULT true, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "UQ_a7eeeb4b551b2629dd9ee964134" UNIQUE ("plate_number"), CONSTRAINT "PK_18d8646b59304dce4af3a9e35b6" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "passwordHash"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "createdAt"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "updatedAt"`);
    await queryRunner.query(`ALTER TABLE "users" ADD "password_hash" text`);
    await queryRunner.query(
      `ALTER TABLE "users" ADD "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "last_login_at" TIMESTAMP WITH TIME ZONE`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "FK_cec43742cd6dea0e8fcae3e29d8" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "ride_requests" ADD CONSTRAINT "FK_575b85b47b55e9db7f417d9615d" FOREIGN KEY ("rider_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "trip_riders" ADD CONSTRAINT "FK_ca3059c3315c1dbdbf20ad6afdf" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "trip_riders" ADD CONSTRAINT "FK_948ebe379770af13cc1ee28f5a4" FOREIGN KEY ("rider_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "trip_events" ADD CONSTRAINT "FK_7f990838ba955f659ec0abfcb31" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "trips" ADD CONSTRAINT "FK_9e5c1f3a92e0b51914f0b55e242" FOREIGN KEY ("driver_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "audit_logs" ADD CONSTRAINT "FK_f160d97a931844109de9d04228f" FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "audit_logs" ADD CONSTRAINT "FK_c49454aef596e6f9dc3eb64f3c6" FOREIGN KEY ("target_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "vehicles" ADD CONSTRAINT "FK_08d0cec0d40811ede63402e191a" FOREIGN KEY ("driver_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "vehicles" DROP CONSTRAINT "FK_08d0cec0d40811ede63402e191a"`,
    );
    await queryRunner.query(
      `ALTER TABLE "audit_logs" DROP CONSTRAINT "FK_c49454aef596e6f9dc3eb64f3c6"`,
    );
    await queryRunner.query(
      `ALTER TABLE "audit_logs" DROP CONSTRAINT "FK_f160d97a931844109de9d04228f"`,
    );
    await queryRunner.query(
      `ALTER TABLE "trips" DROP CONSTRAINT "FK_9e5c1f3a92e0b51914f0b55e242"`,
    );
    await queryRunner.query(
      `ALTER TABLE "trip_events" DROP CONSTRAINT "FK_7f990838ba955f659ec0abfcb31"`,
    );
    await queryRunner.query(
      `ALTER TABLE "trip_riders" DROP CONSTRAINT "FK_948ebe379770af13cc1ee28f5a4"`,
    );
    await queryRunner.query(
      `ALTER TABLE "trip_riders" DROP CONSTRAINT "FK_ca3059c3315c1dbdbf20ad6afdf"`,
    );
    await queryRunner.query(
      `ALTER TABLE "ride_requests" DROP CONSTRAINT "FK_575b85b47b55e9db7f417d9615d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "FK_cec43742cd6dea0e8fcae3e29d8"`,
    );
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "last_login_at"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "updated_at"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "created_at"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "password_hash"`);
    await queryRunner.query(
      `ALTER TABLE "users" ADD "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()`,
    );
    await queryRunner.query(`ALTER TABLE "users" ADD "passwordHash" text`);
    await queryRunner.query(`DROP TABLE "vehicles"`);
    await queryRunner.query(`DROP TABLE "audit_logs"`);
    await queryRunner.query(`DROP TABLE "trips"`);
    await queryRunner.query(`DROP TYPE "public"."trips_status_enum"`);
    await queryRunner.query(`DROP TABLE "trip_events"`);
    await queryRunner.query(`DROP TABLE "trip_riders"`);
    await queryRunner.query(`DROP TYPE "public"."trip_riders_status_enum"`);
    await queryRunner.query(
      `DROP INDEX "public"."IDX_a48b6399c9111fe3c54ee9b3ab"`,
    );
    await queryRunner.query(`DROP TABLE "ride_requests"`);
    await queryRunner.query(`DROP TYPE "public"."ride_requests_status_enum"`);
    await queryRunner.query(
      `DROP TYPE "public"."ride_requests_ride_type_enum"`,
    );
    await queryRunner.query(`DROP TABLE "driver_profiles"`);
    await queryRunner.query(
      `DROP TYPE "public"."driver_profiles_verification_status_enum"`,
    );
  }
}
