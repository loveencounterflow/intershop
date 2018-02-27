

\set n 10


\pset pager off
\ir '../010-trm.sql'

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _BENCHMARKS_ cascade;
create schema _BENCHMARKS_;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _BENCHMARKS_.multiply( a bigint, b bigint )
  returns bigint immutable strict language plpython3u as $$
  return a * b
  $$
reset role;

-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

-- ---------------------------------------------------------------------------------------------------------
create materialized view _BENCHMARKS_.random_numbers as ( select
    ( random() * 200000 )::bigint as a,
    ( random() * 200000 )::bigint as b
from generate_series ( 1, :n ) as x ( n ) );

select * from _BENCHMARKS_.random_numbers limit 10;
select count(*) from _BENCHMARKS_.random_numbers;


-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
\timing on

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 1 )==---':reset
create materialized view _BENCHMARKS_.plpython3u as (
  select a, b, _BENCHMARKS_.multiply( a, b ) as c from _BENCHMARKS_.random_numbers

  );



-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
\timing off

select * from _BENCHMARKS_.plpython3u limit 3;

