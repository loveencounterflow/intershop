


/* ###################################################################################################### */
\ir './010-trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename intershop/053-immutable.sql
\set signal :green

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists IMMUTABLE cascade; create schema IMMUTABLE;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function IMMUTABLE.record_has_changed( old record, new record, excludes text[] )
  returns boolean language plpgsql as $$ begin
    return ( array_length( akeys( hstore( new ) - hstore( old ) - excludes ), 1 ) > 0 ); end; $$;

create function IMMUTABLE.record_has_changed( old record, new record ) returns boolean language plpgsql as $$
  begin
    return IMMUTABLE.record_has_changed( old, new, array[]::text[] ); end; $$;

/*

* see https://github.com/loveencounterflow/gaps-and-islands#immutable-columns-in-sql
* see datamill table datoms for triggers, should incorporate generalized version

*/


/* ###################################################################################################### */
\echo :red ———{ :filename 3 }———:reset
\quit







