#!/bin/bash
#set -e

# создаем дерикторию для табличного пространства
mkdir -p "/var/lib/postgresql/c3s"

# создаем c3s табличное пространство, пользователя и БД
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE $C3S_USER WITH CREATEROLE LOGIN ENCRYPTED PASSWORD '$C3S_PASSWORD';
    CREATE TABLESPACE c3s OWNER c3s_admin LOCATION '/var/lib/postgresql/c3s';
    CREATE DATABASE c3s TABLESPACE c3s OWNER c3s_admin;
EOSQL

# создаем в БД c3s схему и таблицы
psql -v ON_ERROR_STOP=1 --username "$C3S_USER" --dbname "c3s" <<-EOSQL
CREATE SCHEMA c3s AUTHORIZATION c3s_admin;

-- Table: c3s.user
CREATE TABLE c3s."user"
(
    id uuid NOT NULL,
    username character(50) COLLATE pg_catalog."default" NOT NULL,
    password_hash character(50) COLLATE pg_catalog."default" NOT NULL,
    first_name character(50) COLLATE pg_catalog."default" NOT NULL,
    last_name character(50) COLLATE pg_catalog."default" NOT NULL,
    middle_name character(50) COLLATE pg_catalog."default" NOT NULL,
    birthdate date NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    CONSTRAINT user_pkey PRIMARY KEY (id)
        USING INDEX TABLESPACE c3s
);

-- Table: c3s.permision
CREATE TABLE c3s.permission
(
    id serial NOT NULL,
    value character(50) COLLATE pg_catalog."default" NOT NULL,
    title character(250) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT id PRIMARY KEY (id)
        USING INDEX TABLESPACE c3s
);

-- Table: c3s.pixel
CREATE TABLE c3s.pixel
(
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    scene_id uuid NOT NULL,
    status character(50) COLLATE pg_catalog."default" NOT NULL,
    x integer,
    y integer,
    z integer,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    CONSTRAINT pixel_pkey PRIMARY KEY (id)
        USING INDEX TABLESPACE c3s,
    CONSTRAINT user_id FOREIGN KEY (user_id)
        REFERENCES c3s."user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
        NOT VALID
);

-- Table: c3s.scene
CREATE TABLE c3s.scene
(
    id uuid NOT NULL,
    method_id integer NOT NULL,
    user_id uuid NOT NULL,
    name character(200) COLLATE pg_catalog."default" NOT NULL,
    location character(200) COLLATE pg_catalog."default" NOT NULL,
    description character(1000) COLLATE pg_catalog."default" NOT NULL,
    start timestamp without time zone,
    method_params jsonb,
    created time without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    CONSTRAINT scene_pkey PRIMARY KEY (id)
        USING INDEX TABLESPACE c3s,
    CONSTRAINT user_id FOREIGN KEY (user_id)
        REFERENCES c3s."user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

-- Table: c3s.user_permission
CREATE TABLE c3s.user_permission
(
    id serial NOT NULL,
    user_id uuid NOT NULL,
    permission_id integer NOT NULL,
    created timestamp without time zone NOT NULL,
    updated timestamp without time zone NOT NULL,
    CONSTRAINT user_permission_pkey PRIMARY KEY (id)
        USING INDEX TABLESPACE c3s,
    CONSTRAINT permission_id FOREIGN KEY (id)
        REFERENCES c3s.permission (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT user_id FOREIGN KEY (user_id)
        REFERENCES c3s."user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

EOSQL
