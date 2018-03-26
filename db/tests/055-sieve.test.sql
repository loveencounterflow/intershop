


/* ###################################################################################################### */
\ir './start.test.sql'
-- \pset pager on
\timing on

begin transaction;
drop schema if exists _SIEVE_ cascade;
create schema _SIEVE_;
drop schema if exists SIEVE cascade;
\ir '../055-sieve.sql'
-- commit;
-- \quit

-- ---------------------------------------------------------------------------------------------------------
create materialized view _SIEVE_.some_numbers as ( select
  n                             as n,
  SIEVE.fingerprint( n::text )  as fingerprint
  from generate_series( 10000, 19999 ) as n );

-- select * from _SIEVE_.some_numbers;

select stencil, pattern from SIEVE.new_sieve( 8 ) as sieve;
select stencil, pattern from SIEVE.new_sieve( 8 ) as sieve;

-- ---------------------------------------------------------------------------------------------------------
with sieve as ( select * from SIEVE.new_small_sieve( 20, 10000 ) )
select
    n                             as n,
    fingerprint                   as fingerprint
  from
    _SIEVE_.some_numbers,
    sieve
  where SIEVE.is_matching( fingerprint, sieve )
  order by random()
  ;

-- ---------------------------------------------------------------------------------------------------------
with sieve as ( select * from SIEVE.new_big_sieve( 20, 10000 ) )
  select count(*) from _SIEVE_.some_numbers, sieve where SIEVE.is_matching( fingerprint, sieve );

rollback transaction;

/* ###################################################################################################### */
\ir './stop.test.sql'




