

-- \set ECHO queries

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename intershop/054-vnr.sql
\set signal :green

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists VNR cascade;
create schema VNR;




-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
create domain VNR.vnr as float8[] check ( coalesce( array_length( value, 1 ) ) > 0 );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function VNR.push( ¶vnr VNR.vnr, ¶nr float8 default 0 )
  returns VNR.vnr immutable parallel safe language sql as $$
  select array_append( ¶vnr, ¶nr )::VNR.vnr; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function VNR.cat( ¶vnr1 VNR.vnr, ¶vnr2 VNR.vnr )
  returns VNR.vnr immutable parallel safe language sql as $$
  select array_cat( ¶vnr1, ¶vnr2 )::VNR.vnr; $$;



/* ###################################################################################################### */
\echo :red ———{ :filename 3 }———:reset
\quit

