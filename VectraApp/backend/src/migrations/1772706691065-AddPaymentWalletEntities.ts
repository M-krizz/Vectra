import { MigrationInterface, QueryRunner } from "typeorm";

export class AddPaymentWalletEntities1772706691065 implements MigrationInterface {
    name = 'AddPaymentWalletEntities1772706691065'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "ride_requests" DROP CONSTRAINT "FK_pool_group_id"`);
        await queryRunner.query(`ALTER TABLE "ride_requests" DROP CONSTRAINT "FK_ride_requests_pool_group_id"`);
        await queryRunner.query(`CREATE TYPE "public"."payments_method_enum" AS ENUM('CASH', 'WALLET', 'UPI', 'CARD')`);
        await queryRunner.query(`CREATE TYPE "public"."payments_status_enum" AS ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')`);
        await queryRunner.query(`CREATE TYPE "public"."payments_transactiontype_enum" AS ENUM('TRIP_FARE', 'WALLET_TOPUP', 'REFUND', 'WITHDRAWAL')`);
        await queryRunner.query(`CREATE TABLE "payments" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "user_id" uuid NOT NULL, "trip_id" uuid, "amount" numeric(10,2) NOT NULL, "currency" character varying(3) NOT NULL DEFAULT 'INR', "method" "public"."payments_method_enum" NOT NULL, "status" "public"."payments_status_enum" NOT NULL DEFAULT 'PENDING', "transactionType" "public"."payments_transactiontype_enum" NOT NULL, "gateway_transaction_id" character varying, "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_197ab7af18c93fbb0c9b28b4a59" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."safety_incidents_status_enum" AS ENUM('OPEN', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')`);
        await queryRunner.query(`CREATE TYPE "public"."safety_incidents_severity_enum" AS ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')`);
        await queryRunner.query(`CREATE TABLE "safety_incidents" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "description" text NOT NULL, "status" "public"."safety_incidents_status_enum" NOT NULL DEFAULT 'OPEN', "severity" "public"."safety_incidents_severity_enum" NOT NULL DEFAULT 'MEDIUM', "resolution" text, "resolved_by_id" uuid, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "resolved_at" TIMESTAMP WITH TIME ZONE, "ride_id" uuid, "reported_by_id" uuid, CONSTRAINT "PK_3c342c47c53790c3f55ea67723a" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "wallets" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "user_id" uuid NOT NULL, "balance" numeric(10,2) NOT NULL DEFAULT '0', "currency" character varying(3) NOT NULL DEFAULT 'INR', "is_active" boolean NOT NULL DEFAULT true, "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_92558c08091598f7a4439586cda" UNIQUE ("user_id"), CONSTRAINT "REL_92558c08091598f7a4439586cd" UNIQUE ("user_id"), CONSTRAINT "PK_8402e5df5a30a229380e83e4f7e" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "messages" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "content" text NOT NULL, "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "ride_id" uuid, "sender_id" uuid, CONSTRAINT "PK_18325f38ae6de43878487eff986" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "name"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "password_hash"`);
        await queryRunner.query(`ALTER TABLE "driver_profiles" DROP COLUMN "verification_status"`);
        await queryRunner.query(`DROP TYPE "public"."driver_profiles_verification_status_enum"`);
        await queryRunner.query(`CREATE TYPE "public"."trip_riders_payment_status_enum" AS ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')`);
        await queryRunner.query(`ALTER TABLE "trip_riders" ADD "payment_status" "public"."trip_riders_payment_status_enum" NOT NULL DEFAULT 'PENDING'`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "email"`);
        await queryRunner.query(`ALTER TABLE "users" ADD "email" character varying(320)`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email")`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_a000cca60bcf04454e727699490"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "phone"`);
        await queryRunner.query(`ALTER TABLE "users" ADD "phone" character varying(24)`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_a000cca60bcf04454e727699490" UNIQUE ("phone")`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "vehicle_type"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "vehicle_type" character varying(50) NOT NULL`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "make"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "make" character varying(50)`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "model"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "model" character varying(50)`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP CONSTRAINT "UQ_a7eeeb4b551b2629dd9ee964134"`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "plate_number"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "plate_number" character varying(20) NOT NULL`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD CONSTRAINT "UQ_a7eeeb4b551b2629dd9ee964134" UNIQUE ("plate_number")`);
        await queryRunner.query(`ALTER TABLE "payments" ADD CONSTRAINT "FK_427785468fb7d2733f59e7d7d39" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "payments" ADD CONSTRAINT "FK_bd02a6beaa5c282445abc4b3507" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "ride_requests" ADD CONSTRAINT "FK_5309d8619a9be7242e891cc6722" FOREIGN KEY ("pool_group_id") REFERENCES "pool_groups"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "safety_incidents" ADD CONSTRAINT "FK_aa42e04c776f1135c4ddc6a641b" FOREIGN KEY ("ride_id") REFERENCES "ride_requests"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "safety_incidents" ADD CONSTRAINT "FK_69e852c11316648a58779c3cfbf" FOREIGN KEY ("reported_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "wallets" ADD CONSTRAINT "FK_92558c08091598f7a4439586cda" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "messages" ADD CONSTRAINT "FK_8bae51e7d7a6c9bfe4262535a45" FOREIGN KEY ("ride_id") REFERENCES "ride_requests"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "messages" ADD CONSTRAINT "FK_22133395bd13b970ccd0c34ab22" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "messages" DROP CONSTRAINT "FK_22133395bd13b970ccd0c34ab22"`);
        await queryRunner.query(`ALTER TABLE "messages" DROP CONSTRAINT "FK_8bae51e7d7a6c9bfe4262535a45"`);
        await queryRunner.query(`ALTER TABLE "wallets" DROP CONSTRAINT "FK_92558c08091598f7a4439586cda"`);
        await queryRunner.query(`ALTER TABLE "safety_incidents" DROP CONSTRAINT "FK_69e852c11316648a58779c3cfbf"`);
        await queryRunner.query(`ALTER TABLE "safety_incidents" DROP CONSTRAINT "FK_aa42e04c776f1135c4ddc6a641b"`);
        await queryRunner.query(`ALTER TABLE "ride_requests" DROP CONSTRAINT "FK_5309d8619a9be7242e891cc6722"`);
        await queryRunner.query(`ALTER TABLE "payments" DROP CONSTRAINT "FK_bd02a6beaa5c282445abc4b3507"`);
        await queryRunner.query(`ALTER TABLE "payments" DROP CONSTRAINT "FK_427785468fb7d2733f59e7d7d39"`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP CONSTRAINT "UQ_a7eeeb4b551b2629dd9ee964134"`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "plate_number"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "plate_number" text NOT NULL`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD CONSTRAINT "UQ_a7eeeb4b551b2629dd9ee964134" UNIQUE ("plate_number")`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "model"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "model" text`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "make"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "make" text`);
        await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "vehicle_type"`);
        await queryRunner.query(`ALTER TABLE "vehicles" ADD "vehicle_type" text NOT NULL`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_a000cca60bcf04454e727699490"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "phone"`);
        await queryRunner.query(`ALTER TABLE "users" ADD "phone" text`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_a000cca60bcf04454e727699490" UNIQUE ("phone")`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3"`);
        await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "email"`);
        await queryRunner.query(`ALTER TABLE "users" ADD "email" text`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email")`);
        await queryRunner.query(`ALTER TABLE "trip_riders" DROP COLUMN "payment_status"`);
        await queryRunner.query(`DROP TYPE "public"."trip_riders_payment_status_enum"`);
        await queryRunner.query(`CREATE TYPE "public"."driver_profiles_verification_status_enum" AS ENUM('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED')`);
        await queryRunner.query(`ALTER TABLE "driver_profiles" ADD "verification_status" "public"."driver_profiles_verification_status_enum" NOT NULL DEFAULT 'PENDING'`);
        await queryRunner.query(`ALTER TABLE "users" ADD "password_hash" text`);
        await queryRunner.query(`ALTER TABLE "users" ADD "name" text`);
        await queryRunner.query(`DROP TABLE "messages"`);
        await queryRunner.query(`DROP TABLE "wallets"`);
        await queryRunner.query(`DROP TABLE "safety_incidents"`);
        await queryRunner.query(`DROP TYPE "public"."safety_incidents_severity_enum"`);
        await queryRunner.query(`DROP TYPE "public"."safety_incidents_status_enum"`);
        await queryRunner.query(`DROP TABLE "payments"`);
        await queryRunner.query(`DROP TYPE "public"."payments_transactiontype_enum"`);
        await queryRunner.query(`DROP TYPE "public"."payments_status_enum"`);
        await queryRunner.query(`DROP TYPE "public"."payments_method_enum"`);
        await queryRunner.query(`ALTER TABLE "ride_requests" ADD CONSTRAINT "FK_ride_requests_pool_group_id" FOREIGN KEY ("pool_group_id") REFERENCES "pool_groups"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "ride_requests" ADD CONSTRAINT "FK_pool_group_id" FOREIGN KEY ("pool_group_id") REFERENCES "pool_groups"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
    }

}
