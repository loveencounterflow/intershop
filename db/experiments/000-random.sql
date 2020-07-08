
/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename interplot/db/experiments/000-random.sql
\set signal :red
\set ECHO none
begin transaction;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists RANDOM cascade; create schema RANDOM;

-- thx to
-- https://www.endpoint.com/blog/2020/07/02/random-strings-and-integers-that-actually-arent

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
create or replace function RANDOM.pseudocrypt( value integer )
  returns integer immutable strict parallel safe language plpgsql as $$
  declare
    key   numeric;
    l1    int;
    l2    int;
    r1    int;
    r2    int;
    i     int := 0;
  begin
    l1  :=  ( value >> 16 ) & 65535;
    r1  :=  value & 65535;
    while i < 3 loop
      -- key can be any function that returns numeric between 0 and 1
      key :=  ( ( ( 1366 * r1 + 150889 ) % 714025 ) / 714025.0 );
      l2  :=  r1;
      r2  :=  l1 # (key * 32767)::int;
      l1  :=  l2;
      r1  :=  r2;
      i   :=  i + 1;
      end loop;
    return ( ( r1 << 16 ) + l1 ); end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
create or replace function RANDOM.text_from_integer( n int )
  returns text immutable strict parallel safe language plpgsql as $$
  declare
    -- alphabet  text  :=  'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789';
    alphabet  text  :=  'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ';
    base      int   :=  length( alphabet );
    R         text  :=  '';
  begin
    loop
      R := R || substr( alphabet, 1 + ( n % base )::int, 1 );
      n := n / base;
      exit when n = 0;
      end loop;
    return R; end $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
select RANDOM.text_from_integer( RANDOM.pseudocrypt( x ) ) from generate_series( 1, 10 ) as x;



/* ###################################################################################################### */
\echo :red ———{ :filename 13 }———:reset
\quit

