

-- ---------------------------------------------------------------------------------------------------------
\pset pager off
\ir '../010-trm.sql'
\echo :cyan'——————————————————————— benchmark-pl-languages-002-execute.sql ———————————————————————':reset
\set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
select * from _BENCHMARKS_.random_numbers limit 10;
-- select count(*) from _BENCHMARKS_.random_numbers;

-- ---------------------------------------------------------------------------------------------------------
drop materialized view if exists _BENCHMARKS_.results_sql         cascade;
drop materialized view if exists _BENCHMARKS_.results_plpgsql     cascade;
drop materialized view if exists _BENCHMARKS_.results_plpython3u  cascade;
drop materialized view if exists _BENCHMARKS_.results_pllua       cascade;


-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
\timing on

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( sql )==---':reset
create materialized view _BENCHMARKS_.results_sql as (
  select a, b, _BENCHMARKS_.sql_multiply( a, b ) as c from _BENCHMARKS_.random_numbers );

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( plpgsql )==---':reset
create materialized view _BENCHMARKS_.results_plpgsql as (
  select a, b, _BENCHMARKS_.plpgsql_multiply( a, b ) as c from _BENCHMARKS_.random_numbers );

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( plpython3u )==---':reset
create materialized view _BENCHMARKS_.results_plpython3u as (
  select a, b, _BENCHMARKS_.plpython3u_multiply( a, b ) as c from _BENCHMARKS_.random_numbers );

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( pllua )==---':reset
-- set role dba;
create materialized view _BENCHMARKS_.results_pllua as (
  select a, b, _BENCHMARKS_.pllua_multiply( a, b ) as c from _BENCHMARKS_.random_numbers );
-- reset role;



-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
\timing off

select * from _BENCHMARKS_.results_sql limit 3;
select * from _BENCHMARKS_.results_plpgsql limit 3;
select * from _BENCHMARKS_.results_plpython3u limit 3;
-- set role dba;
select * from _BENCHMARKS_.results_pllua limit 3;
-- reset role;



