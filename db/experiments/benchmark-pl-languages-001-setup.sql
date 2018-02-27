

-- ---------------------------------------------------------------------------------------------------------
\set n 1e2
\set n 1281316


-- ---------------------------------------------------------------------------------------------------------
\pset pager off
\ir '../010-trm.sql'
\echo :cyan'——————————————————————— benchmark-pl-languages-001-setup.sql ———————————————————————':reset

-- ---------------------------------------------------------------------------------------------------------
set role dba;
drop schema if exists pllua cascade;
create schema pllua;
-- drop extension pllua cascade;
create extension if not exists pllua;
reset role;

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _BENCHMARKS_ cascade;
create schema _BENCHMARKS_;

-- ---------------------------------------------------------------------------------------------------------
create function _BENCHMARKS_.sql_multiply( a bigint, b bigint )
  returns bigint immutable strict language sql as $$
  select a * b; $$;

-- ---------------------------------------------------------------------------------------------------------
create function _BENCHMARKS_.plpgsql_multiply( a bigint, b bigint )
  returns bigint immutable strict language plpgsql as $$
  begin
    return a * b;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _BENCHMARKS_.plpython3u_multiply( a bigint, b bigint )
  returns bigint immutable strict language plpython3u as $$
  return a * b
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _BENCHMARKS_.pllua_multiply( a bigint, b bigint )
  returns bigint immutable strict language pllua as $$
  return a * b
  $$;
reset role;

-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

-- ---------------------------------------------------------------------------------------------------------
create materialized view _BENCHMARKS_.random_numbers as ( select
    ( random() * 200000 )::bigint as a,
    ( random() * 200000 )::bigint as b
from generate_series ( 1, :n ) as x ( n ) );


-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
select * from _BENCHMARKS_.random_numbers limit 10;

\ir './benchmark-pl-languages-002-execute.sql'
