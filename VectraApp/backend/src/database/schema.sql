-- =========================
-- VECTRA BASE SCHEMA
-- PostgreSQL + PostGIS
-- =========================

-- 1) Extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid()

-- 2) Enums (you can also do lookup tables instead)
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('RIDER', 'DRIVER', 'ADMIN');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE account_status AS ENUM ('ACTIVE', 'SUSPENDED', 'DELETED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE driver_verification_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE ride_request_status AS ENUM ('REQUESTED', 'MATCHING', 'EXPIRED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE trip_status AS ENUM ('REQUESTED', 'ASSIGNED', 'ARRIVING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 3) Users (common for Rider/Driver/Admin)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role user_role NOT NULL,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  password_hash TEXT, -- optional if OTP-only
  name TEXT,
  status account_status NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);

-- 4) Driver profile (only for drivers)
CREATE TABLE IF NOT EXISTS driver_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  verification_status driver_verification_status NOT NULL DEFAULT 'PENDING',
  rating_avg NUMERIC(3,2) NOT NULL DEFAULT 0,
  rating_count INT NOT NULL DEFAULT 0,
  completion_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  online_status BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5) Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vehicle_type TEXT NOT NULL, -- e.g., Bike, Sedan, EV
  make TEXT,
  model TEXT,
  plate_number TEXT UNIQUE NOT NULL,
  seating_capacity INT NOT NULL CHECK (seating_capacity >= 1),
  emission_factor_g_per_km NUMERIC(10,2), -- for CO2 calculations
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6) Ride Requests (before assignment)
CREATE TABLE IF NOT EXISTS ride_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pickup_point GEOGRAPHY(Point, 4326) NOT NULL,
  drop_point GEOGRAPHY(Point, 4326) NOT NULL,
  pickup_address TEXT,
  drop_address TEXT,
  ride_type TEXT NOT NULL CHECK (ride_type IN ('SOLO', 'POOL')),
  status ride_request_status NOT NULL DEFAULT 'REQUESTED',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ
);

-- Helpful index for geo radius search
CREATE INDEX IF NOT EXISTS idx_ride_requests_pickup_gist
ON ride_requests USING GIST (pickup_point);

-- 7) Trips
CREATE TABLE IF NOT EXISTS trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_user_id UUID REFERENCES users(id),
  status trip_status NOT NULL DEFAULT 'REQUESTED',
  assigned_at TIMESTAMPTZ,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  current_route_polyline TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8) Trip Riders (supports pooling)
CREATE TABLE IF NOT EXISTS trip_riders (
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  rider_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pickup_point GEOGRAPHY(Point, 4326) NOT NULL,
  drop_point GEOGRAPHY(Point, 4326) NOT NULL,
  pickup_sequence INT,
  drop_sequence INT,
  fare_share NUMERIC(10,2),
  status TEXT NOT NULL DEFAULT 'JOINED' CHECK (status IN ('JOINED','CANCELLED','NO_SHOW')),
  PRIMARY KEY (trip_id, rider_user_id)
);

-- 9) Trip Events (audit of state changes)
CREATE TABLE IF NOT EXISTS trip_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 10) Audit Logs (admin actions, role changes, bans)
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id),
  target_user_id UUID REFERENCES users(id),
  action_type TEXT NOT NULL,
  reason TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 11) Default Admin User Seeding
INSERT INTO users (role, email, phone, name, status, password_hash)
VALUES ('ADMIN', 'admin@vectra.app', '+10000000000', 'Vectra Superadmin', 'ACTIVE', '$2b$10$/I0kRIJakPc9nUoiw1kgTLUYM4.lESOqqQiS4gC2t1wY3/O/RcihC')
ON CONFLICT (email) DO NOTHING;
