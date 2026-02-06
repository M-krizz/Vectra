import { MigrationInterface, QueryRunner } from 'typeorm';

export class AuthMerge1769867704083 implements MigrationInterface {
  name = 'AuthMerge1769867704083';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Create new enums
    await queryRunner.query(
      `CREATE TYPE "public"."role_change_audits_old_role_enum" AS ENUM('RIDER', 'DRIVER', 'ADMIN', 'COMMUNITY_ADMIN')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."role_change_audits_new_role_enum" AS ENUM('RIDER', 'DRIVER', 'ADMIN', 'COMMUNITY_ADMIN')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."documents_doc_type_enum" AS ENUM('DRIVERS_LICENSE', 'VEHICLE_REGISTRATION', 'INSURANCE', 'BACKGROUND_CHECK', 'PROFILE_PHOTO')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."compliance_events_event_type_enum" AS ENUM('DOCUMENT_SUBMITTED', 'DOCUMENT_APPROVED', 'DOCUMENT_REJECTED', 'DOCUMENT_EXPIRED', 'EXPIRY_NOTICE', 'DRIVER_VERIFIED', 'DRIVER_SUSPENDED')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."admin_audits_action_enum" AS ENUM('SUSPEND_USER', 'REINSTATE_USER', 'CHANGE_ROLE', 'APPROVE_DRIVER', 'REJECT_DRIVER', 'DELETE_USER', 'BAN_USER')`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."driver_profiles_status_enum" AS ENUM('PENDING_VERIFICATION', 'DOCUMENTS_SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'SUSPENDED')`,
    );

    // Create new tables
    await queryRunner.query(
      `CREATE TABLE "role_change_audits" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "user_id" uuid NOT NULL, "changed_by_id" uuid NOT NULL, "old_role" "public"."role_change_audits_old_role_enum" NOT NULL, "new_role" "public"."role_change_audits_new_role_enum" NOT NULL, "reason" character varying(500), "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_07bf63e6bb4bf77cb0aa90d3a03" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "documents" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "driver_profile_id" uuid NOT NULL, "doc_type" "public"."documents_doc_type_enum" NOT NULL, "s3_key" character varying(512) NOT NULL, "file_name" character varying(255), "is_approved" boolean NOT NULL DEFAULT false, "rejection_reason" character varying(255), "expires_at" TIMESTAMP WITH TIME ZONE, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_ac51aa5181ee2036f5ca482857c" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "compliance_events" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "driver_profile_id" uuid NOT NULL, "event_type" "public"."compliance_events_event_type_enum" NOT NULL, "meta" jsonb NOT NULL DEFAULT '{}', "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_7b8ce10267f7885587d185b33b3" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "admin_audits" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "performed_by_id" uuid NOT NULL, "target_user_id" uuid NOT NULL, "action" "public"."admin_audits_action_enum" NOT NULL, "reason" character varying(500), "meta" jsonb NOT NULL DEFAULT '{}', "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_c007dcf4381621d09bfcc217600" PRIMARY KEY ("id"))`,
    );

    // Add new columns to users table
    await queryRunner.query(
      `ALTER TABLE "users" ADD "full_name" character varying(150)`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "is_verified" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "profile_image_key" character varying(255)`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "preferred_locations" jsonb NOT NULL DEFAULT '[]'`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "share_location" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "share_ride_history" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "is_active" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "is_suspended" boolean NOT NULL DEFAULT false`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "suspension_reason" character varying(255)`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ADD "deleted_at" TIMESTAMP WITH TIME ZONE`,
    );

    // Add new columns to vehicles
    await queryRunner.query(`ALTER TABLE "vehicles" ADD "year" integer`);
    await queryRunner.query(
      `ALTER TABLE "vehicles" ADD "color" character varying(30)`,
    );

    // Add new columns to driver_profiles
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD "id" uuid NOT NULL DEFAULT uuid_generate_v4()`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "PK_cec43742cd6dea0e8fcae3e29d8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "PK_8bc47bfb3059ca27eaf41c2545e" PRIMARY KEY ("user_id", "id")`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD "license_number" character varying(64)`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD "license_state" character varying(20)`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD "status" "public"."driver_profiles_status_enum" NOT NULL DEFAULT 'PENDING_VERIFICATION'`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD "meta" jsonb NOT NULL DEFAULT '{}'`,
    );

    // Add new columns to refresh_tokens
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ADD "device_info" character varying(255)`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ADD "ip" character varying(80)`,
    );
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" ADD "last_used_at" TIMESTAMP WITH TIME ZONE`,
    );

    // Update users role enum to include COMMUNITY_ADMIN
    await queryRunner.query(
      `ALTER TYPE "public"."users_role_enum" RENAME TO "users_role_enum_old"`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."users_role_enum" AS ENUM('RIDER', 'DRIVER', 'ADMIN', 'COMMUNITY_ADMIN')`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "role" TYPE "public"."users_role_enum" USING "role"::"text"::"public"."users_role_enum"`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'RIDER'`,
    );
    await queryRunner.query(`DROP TYPE "public"."users_role_enum_old"`);

    // Fix driver_profiles primary key
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "FK_cec43742cd6dea0e8fcae3e29d8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "PK_8bc47bfb3059ca27eaf41c2545e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "PK_6e002fc8a835351e070978fcad4" PRIMARY KEY ("id")`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "UQ_cec43742cd6dea0e8fcae3e29d8" UNIQUE ("user_id")`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "FK_cec43742cd6dea0e8fcae3e29d8" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    // Add foreign keys
    await queryRunner.query(
      `ALTER TABLE "role_change_audits" ADD CONSTRAINT "FK_7d49e39af9cbf81ce31037601dc" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "role_change_audits" ADD CONSTRAINT "FK_2e12887b235652e39bd0d6e9658" FOREIGN KEY ("changed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "documents" ADD CONSTRAINT "FK_67392d320df116a88aea456c00d" FOREIGN KEY ("driver_profile_id") REFERENCES "driver_profiles"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "compliance_events" ADD CONSTRAINT "FK_729171d2391ca682f477635f4d2" FOREIGN KEY ("driver_profile_id") REFERENCES "driver_profiles"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "admin_audits" ADD CONSTRAINT "FK_7f4689cc36c24b5038a089db49a" FOREIGN KEY ("performed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "admin_audits" ADD CONSTRAINT "FK_875cef662a8217395ad2e34a688" FOREIGN KEY ("target_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop foreign keys
    await queryRunner.query(
      `ALTER TABLE "admin_audits" DROP CONSTRAINT "FK_875cef662a8217395ad2e34a688"`,
    );
    await queryRunner.query(
      `ALTER TABLE "admin_audits" DROP CONSTRAINT "FK_7f4689cc36c24b5038a089db49a"`,
    );
    await queryRunner.query(
      `ALTER TABLE "compliance_events" DROP CONSTRAINT "FK_729171d2391ca682f477635f4d2"`,
    );
    await queryRunner.query(
      `ALTER TABLE "documents" DROP CONSTRAINT "FK_67392d320df116a88aea456c00d"`,
    );
    await queryRunner.query(
      `ALTER TABLE "role_change_audits" DROP CONSTRAINT "FK_2e12887b235652e39bd0d6e9658"`,
    );
    await queryRunner.query(
      `ALTER TABLE "role_change_audits" DROP CONSTRAINT "FK_7d49e39af9cbf81ce31037601dc"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "FK_cec43742cd6dea0e8fcae3e29d8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "UQ_cec43742cd6dea0e8fcae3e29d8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "PK_6e002fc8a835351e070978fcad4"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "PK_8bc47bfb3059ca27eaf41c2545e" PRIMARY KEY ("user_id", "id")`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "FK_cec43742cd6dea0e8fcae3e29d8" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );

    // Revert users role enum
    await queryRunner.query(
      `CREATE TYPE "public"."users_role_enum_old" AS ENUM('RIDER', 'DRIVER', 'ADMIN')`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "role" DROP DEFAULT`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" ALTER COLUMN "role" TYPE "public"."users_role_enum_old" USING "role"::"text"::"public"."users_role_enum_old"`,
    );
    await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
    await queryRunner.query(
      `ALTER TYPE "public"."users_role_enum_old" RENAME TO "users_role_enum"`,
    );

    // Drop columns from refresh_tokens
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" DROP COLUMN "last_used_at"`,
    );
    await queryRunner.query(`ALTER TABLE "refresh_tokens" DROP COLUMN "ip"`);
    await queryRunner.query(
      `ALTER TABLE "refresh_tokens" DROP COLUMN "device_info"`,
    );

    // Drop columns from driver_profiles
    await queryRunner.query(`ALTER TABLE "driver_profiles" DROP COLUMN "meta"`);
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP COLUMN "status"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP COLUMN "license_state"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP COLUMN "license_number"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" DROP CONSTRAINT "PK_8bc47bfb3059ca27eaf41c2545e"`,
    );
    await queryRunner.query(
      `ALTER TABLE "driver_profiles" ADD CONSTRAINT "PK_cec43742cd6dea0e8fcae3e29d8" PRIMARY KEY ("user_id")`,
    );
    await queryRunner.query(`ALTER TABLE "driver_profiles" DROP COLUMN "id"`);

    // Drop columns from vehicles
    await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "color"`);
    await queryRunner.query(`ALTER TABLE "vehicles" DROP COLUMN "year"`);

    // Drop columns from users
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "deleted_at"`);
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN "suspension_reason"`,
    );
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "is_suspended"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "is_active"`);
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN "share_ride_history"`,
    );
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "share_location"`);
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN "preferred_locations"`,
    );
    await queryRunner.query(
      `ALTER TABLE "users" DROP COLUMN "profile_image_key"`,
    );
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "is_verified"`);
    await queryRunner.query(`ALTER TABLE "users" DROP COLUMN "full_name"`);

    // Drop tables
    await queryRunner.query(`DROP TABLE "admin_audits"`);
    await queryRunner.query(`DROP TABLE "compliance_events"`);
    await queryRunner.query(`DROP TABLE "documents"`);
    await queryRunner.query(`DROP TABLE "role_change_audits"`);

    // Drop enums
    await queryRunner.query(`DROP TYPE "public"."driver_profiles_status_enum"`);
    await queryRunner.query(`DROP TYPE "public"."admin_audits_action_enum"`);
    await queryRunner.query(
      `DROP TYPE "public"."compliance_events_event_type_enum"`,
    );
    await queryRunner.query(`DROP TYPE "public"."documents_doc_type_enum"`);
    await queryRunner.query(
      `DROP TYPE "public"."role_change_audits_new_role_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE "public"."role_change_audits_old_role_enum"`,
    );
  }
}
