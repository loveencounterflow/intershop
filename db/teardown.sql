
\ir './010-trm.sql'
\pset pager off
\pset tuples_only on

\echo
\echo :yellow'—————————————————————————————————————————————————————————————————————————————————':reset
\echo :yellow'          In case the below command fails with an error message like             ':reset
\echo
\echo :yellow'          ERROR:  syntax error at or near ":"                                    ':reset
\echo
\echo :yellow'          make sure psql variables :app_user and :app_db are properly set        ':reset
\echo :yellow'          (e.g. by running this script via the `bin/rebuild executable)          ':reset
\echo :yellow'—————————————————————————————————————————————————————————————————————————————————':reset
\echo

-- \set app_user     intershop
-- \set app_db       intershop
\echo :X'targetting app user ':white:app_user :O
\echo :X'targetting app DB   ':white:app_db   :O

select count( pg_terminate_backend( pid ) )
from pg_stat_activity
where datname = :'app_db';

drop database if exists :app_db;
drop role if exists :app_user;
-- drop role if exists dba;

/* thx to https://pastebin.com/bgFDhNvP */
do $$
  begin
    if not exists ( select * from pg_roles where rolname = 'dba' ) then
      create role dba with superuser;
      end if;
    end $$;

create user :app_user with
  nocreatedb
  nocreaterole
  noinherit
  login
  noreplication
  nobypassrls
  in role dba;

create database :app_db with owner = :app_user;
\echo created db :app_db owned by :app_user


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
drop database if exists :app_db;
create database :app_db with
  template    = template0
  encoding    = 'UTF8'
  lc_collate  = 'C'
  lc_ctype    = 'C';
  -- lc_collate  = 'C.UTF-8'
  -- lc_ctype    = 'C.UTF-8';
-- select current_user;
-- xxx;
alter database :app_db owner to :app_user;
-- grant create on database :app_db to :app_user;
\connect :app_db

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

