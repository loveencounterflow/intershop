

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

comment on function VNR.push( VNR.vnr, float8 ) is 'Given a VNR and a number (`float8`), return a
  VNR that results from appending the number to the VNR.';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function VNR.cat( ¶vnr1 VNR.vnr, ¶vnr2 VNR.vnr )
  returns VNR.vnr immutable parallel safe language sql as $$
  select array_cat( ¶vnr1, ¶vnr2 )::VNR.vnr; $$;

comment on function VNR.cat( VNR.vnr, VNR.vnr ) is 'Given two VNRs, return a VNR that results from
concatenating the elements of both arrays.';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function VNR.smallest()
  returns VNR.vnr immutable parallel safe language sql as $$
  select ( array[ '-infinity'::float ] )::VNR.vnr; $$;

comment on function VNR.smallest is 'Return a VNR with a single element that is negative infinity
(`''+infinity''::float`) and will therefore be ordered before all VNRs with finite leading values.';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function VNR.greatest()
  returns VNR.vnr immutable parallel safe language sql as $$
  select ( array[ '+infinity'::float ] )::VNR.vnr; $$;

comment on function VNR.greatest is 'Return a VNR with a single element that is positive infinity
(`''+infinity''::float`) and will therefore be ordered after all VNRs with finite leading values.';



/* ###################################################################################################### */
\echo :red ———{ :filename 3 }———:reset
\quit

