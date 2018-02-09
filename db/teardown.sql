
\ir './010-trm.sql'
\pset pager off
\pset tuples_only on

\echo
\echo :yellow'—————————————————————————————————————————————————————————————————————————————————':O
\echo :yellow'          In case the below command fails with an error message like             ':O
\echo
\echo :yellow'          ERROR:  syntax error at or near ":"                                    ':O
\echo
\echo :yellow'          make sure psql variables :intershop_db_user and                        ':O
\echo :yellow'          :intershop_db_name are properly set                                    ':O
\echo :yellow'          (e.g. by running this script via the `bin/rebuild executable)          ':O
\echo :yellow'—————————————————————————————————————————————————————————————————————————————————':O
\echo

-- \set intershop_db_user     intershop
-- \set intershop_db_name       intershop
\echo :X'targetting app user ':white:intershop_db_user :O
\echo :X'targetting app DB   ':white:intershop_db_name :O

select count( pg_terminate_backend( pid ) )
from pg_stat_activity
where datname = :'intershop_db_name';

drop database if exists :intershop_db_name;
drop role if exists :intershop_db_user;
-- drop role if exists dba;

/* thx to https://pastebin.com/bgFDhNvP */
do $$
  begin
    if not exists ( select * from pg_roles where rolname = 'dba' ) then
      create role dba with superuser;
      end if;
    end $$;

create user :intershop_db_user with
  nocreatedb
  nocreaterole
  noinherit
  login
  noreplication
  nobypassrls
  in role dba;

create database :intershop_db_name with owner = :intershop_db_user;
\echo created db :intershop_db_name owned by :intershop_db_user


/* Prepare: */
set statement_timeout           = 0;
set lock_timeout                = 0;
set client_encoding             = 'UTF8';
set standard_conforming_strings = on;
set check_function_bodies       = false;
set client_min_messages         = warning;
set row_security                = off;

/* Recreate DB: */
\connect postgres
drop database if exists :intershop_db_name;
create database :intershop_db_name with
  template    = template0
  encoding    = 'UTF8'
  lc_collate  = 'C'
  lc_ctype    = 'C';
  -- lc_collate  = 'C.UTF-8'
  -- lc_ctype    = 'C.UTF-8';
-- select current_user;
-- xxx;
alter database :intershop_db_name owner to :intershop_db_user;
-- grant create on database :intershop_db_name to :intershop_db_user;
\connect :intershop_db_name

/* Restate environmental settings: */
set statement_timeout           = 0;
set lock_timeout                = 0;
set client_encoding             = 'UTF8';
set standard_conforming_strings = on;
set check_function_bodies       = false;
set client_min_messages         = warning;
set row_security                = off;

/* finish: */
\pset pager on
\quit

