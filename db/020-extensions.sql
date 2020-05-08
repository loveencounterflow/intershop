
/*

8888888888 Y88b   d88P 88888888888 8888888888 888b    888  .d8888b. 8888888  .d88888b.  888b    888  .d8888b.
888         Y88b d88P      888     888        8888b   888 d88P  Y88b  888   d88P" "Y88b 8888b   888 d88P  Y88b
888          Y88o88P       888     888        88888b  888 Y88b.       888   888     888 88888b  888 Y88b.
8888888       Y888P        888     8888888    888Y88b 888  "Y888b.    888   888     888 888Y88b 888  "Y888b.
888           d888b        888     888        888 Y88b888     "Y88b.  888   888     888 888 Y88b888     "Y88b.
888          d88888b       888     888        888  Y88888       "888  888   888     888 888  Y88888       "888
888         d88P Y88b      888     888        888   Y8888 Y88b  d88P  888   Y88b. .d88P 888   Y8888 Y88b  d88P
8888888888 d88P   Y88b     888     8888888888 888    Y888  "Y8888P" 8888888  "Y88888P"  888    Y888  "Y8888P"

*/

-- =========================================================================================================
-- CREATE EXTENSIONS
-- ---------------------------------------------------------------------------------------------------------
create schema _plpgsql;
create schema _pgcrypto;
create schema _tablefunc;

set role dba;
create extension if not exists plsh       with schema pg_catalog;
create extension if not exists plpython3u with schema pg_catalog;
create extension if not exists plpgsql    with schema _plpgsql;
create extension if not exists pgcrypto   with schema _pgcrypto;
create extension if not exists tablefunc  with schema _tablefunc;
create extension if not exists hstore;

-- ---------------------------------------------------------------------------------------------------------
-- /* https://github.com/ChristophBerg/postgresql-unit */
-- create extension if not exists unit;
-- grant select, insert, update on unit_units, unit_prefixes to public;

-- ---------------------------------------------------------------------------------------------------------
set search_path = public, pg_catalog, _plpgsql, _pgcrypto; -- pgunit;
reset role;



\quit


