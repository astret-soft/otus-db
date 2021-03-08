#!/bin/bash
set -e

# создаем дерикторию для табличного пространства
mkdir -p "/var/lib/postgresql/c3s"

# создаем c3s табличное пространство, пользователя и БД
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE c3s_admin WITH CREATEROLE LOGIN ENCRYPTED PASSWORD 'c3s_admin';
    CREATE TABLESPACE c3s OWNER c3s_admin LOCATION '/var/lib/postgresql/c3s';
    CREATE DATABASE c3s TABLESPACE c3s OWNER c3s_admin;
EOSQL
