

-- \set ECHO queries
begin transaction;

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/900-dev.sql
\set signal :blue

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists UDF cascade; create schema UDF;

-- do $$ begin raise sqlstate 'CHX03' using message = 'CHX03 module unfinished'; end; $$;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
-- create function UDF.get_product( ¶n integer, ¶factor integer, ¶facets variadic text[] default '{}'::text[] )
create function UDF.get_product( ¶n integer, ¶factor integer default 1, ¶facets text[] default '{}'::text[] )
  returns integer volatile strict language plpgsql as $$ declare
  begin
    raise notice '^44433^ % % %', ¶n, ¶factor, ¶facets;
    return ¶n * ¶factor;
    end; $$;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
select * from UDF.get_product( 2 );
select * from UDF.get_product( 2, 3 );
-- select * from UDF.get_product( 2, 3, 'x' );
select * from UDF.get_product( 2, ¶factor => 3, ¶facets => array[ 'x' ] );
select * from UDF.get_product( 2, ¶factor => 3, ¶facets => '{x,y,z}' );
select * from UDF.get_product( 2, ¶facets => '{x,y,z}' );


/* ###################################################################################################### */
\echo :red ———{ :filename 22 }———:reset
\quit



