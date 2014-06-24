-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Oct 31 17:36:15 2012
-- 
--
-- Table: event.
--
DROP TABLE "event" CASCADE;
CREATE TABLE "event" (
  "event_id" serial NOT NULL,
  "event_name" text NOT NULL,
  "organizer_name" text NOT NULL,
  "email" text,
  "music_genre" text NOT NULL,
  "artists" text NOT NULL,
  "start_time" timestamp with time zone NOT NULL,
  "more_info_url" text,
  "rsvp_url" text,
  "location_id" integer NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp,
  PRIMARY KEY ("event_id"),
  CONSTRAINT "event_event_name" UNIQUE ("event_name")
);
CREATE INDEX "event_idx_location_id" on "event" ("location_id");

--
-- Table: location.
--
DROP TABLE "location" CASCADE;
CREATE TABLE "location" (
  "location_id" serial NOT NULL,
  "location_type_id" integer NOT NULL,
  "location_name" text NOT NULL,
  "phone" text,
  "address" text NOT NULL,
  "url" text,
  "lat" double precision NOT NULL,
  "long" double precision NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp,
  PRIMARY KEY ("location_id")
);
CREATE INDEX "location_idx_location_type_id" on "location" ("location_type_id");

--
-- Table: location_type.
--
DROP TABLE "location_type" CASCADE;
CREATE TABLE "location_type" (
  "location_type_id" serial NOT NULL,
  "location_type" text NOT NULL,
  "created_at" timestamp NOT NULL,
  PRIMARY KEY ("location_type_id")
);

--
-- Table: role.
--
DROP TABLE "role" CASCADE;
CREATE TABLE "role" (
  "role_id" serial NOT NULL,
  "role_name" text NOT NULL,
  PRIMARY KEY ("role_id"),
  CONSTRAINT "role_role_name" UNIQUE ("role_name")
);

--
-- Table: user_account.
--
DROP TABLE "user_account" CASCADE;
CREATE TABLE "user_account" (
  "user_account_id" serial NOT NULL,
  "email" text NOT NULL,
  "username" text NOT NULL,
  "password" text NOT NULL,
  "city" text,
  "lat" numeric,
  "lng" numeric,
  "active" bool DEFAULT '0' NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp,
  PRIMARY KEY ("user_account_id"),
  CONSTRAINT "user_account_email" UNIQUE ("email")
);

--
-- Table: auth_credential.
--
DROP TABLE "auth_credential" CASCADE;
CREATE TABLE "auth_credential" (
  "auth_credential_id" serial NOT NULL,
  "user_account_id" integer,
  "fb_user_id" bigint,
  "token" text NOT NULL,
  "expires_in" integer,
  "active" bool NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp,
  PRIMARY KEY ("auth_credential_id"),
  CONSTRAINT "auth_credential_token" UNIQUE ("token")
);
CREATE INDEX "auth_credential_idx_user_account_id" on "auth_credential" ("user_account_id");

--
-- Table: user_account_role.
--
DROP TABLE "user_account_role" CASCADE;
CREATE TABLE "user_account_role" (
  "user_account_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp,
  PRIMARY KEY ("user_account_id", "role_id")
);
CREATE INDEX "user_account_role_idx_role_id" on "user_account_role" ("role_id");
CREATE INDEX "user_account_role_idx_user_account_id" on "user_account_role" ("user_account_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "event" ADD CONSTRAINT "event_fk_location_id" FOREIGN KEY ("location_id")
  REFERENCES "location" ("location_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "location" ADD CONSTRAINT "location_fk_location_type_id" FOREIGN KEY ("location_type_id")
  REFERENCES "location_type" ("location_type_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "auth_credential" ADD CONSTRAINT "auth_credential_fk_user_account_id" FOREIGN KEY ("user_account_id")
  REFERENCES "user_account" ("user_account_id") DEFERRABLE;

ALTER TABLE "user_account_role" ADD CONSTRAINT "user_account_role_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "role" ("role_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_account_role" ADD CONSTRAINT "user_account_role_fk_user_account_id" FOREIGN KEY ("user_account_id")
  REFERENCES "user_account" ("user_account_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

