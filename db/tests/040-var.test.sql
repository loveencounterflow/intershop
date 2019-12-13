
\ir ./start.test.sql


/*

888b    888 8888888888 888       888
8888b   888 888        888   o   888
88888b  888 888        888  d8b  888
888Y88b 888 8888888    888 d888b 888
888 Y88b888 888        888d88888b888
888  Y88888 888        88888P Y88888
888   Y8888 888        8888P   Y8888
888    Y888 8888888888 888P     Y888

*/

/* see db/test/040-var.test.sql */

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _VAR_ cascade;
create schema if not exists _VAR_;

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create table _VAR_.variables of U.triple_facet ( key unique not null primary key );

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create or replace function _VAR_.get( ¶key text )
  returns text stable language plpgsql as $$
  declare
    ¶row_count  integer;
    R           text;
  begin
    R := value from U.variables where key = ¶key;
    get diagnostics ¶row_count = row_count;
    if ¶row_count != 1 then raise exception 'variable not found: %', ¶key; end if;
    return R;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create or replace function _VAR_.get( ¶key text, ¶default anyelement )
  returns text stable language plpgsql as $$
  declare
    ¶row_count  integer;
    R           text;
  begin
    R := value from U.variables where key = ¶key;
    get diagnostics ¶row_count = row_count;
    if ¶row_count = 0 then return ¶default; end if;
    if ¶row_count != 1 then raise exception 'variable not found: %', ¶key; end if;
    return R;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create or replace function _VAR_.set( ¶key text, ¶type text, ¶value anyelement )
  returns void volatile language sql as $$
  insert into U.variables values ( ¶key, ¶type, ¶value )
  on conflict ( key ) do update set type = ¶type, value = ¶value; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create or replace function _VAR_.set( ¶key text, ¶value anyelement )
  returns void volatile language sql as $$
  insert into U.variables values ( ¶key, ¶value )
  on conflict ( key ) do update set value = ¶value; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- create or replace function _VAR_.refresh( ¶key text, ¶value anyelement )
--   returns void volatile language sql as $$
--   select 42; $$;

-- select * from U.variables where key ~ 'mojikura' order by key; xxx;

-- ---------------------------------------------------------------------------------------------------------
create function _VAR_.¶resolve( ¶template text ) returns text stable strict language plpgsql as $$
  declare
    R text  := '';
  begin
    perform log( '44452', regexp_split_to_array( ¶template, '(?<!\\)\${' )::text );
    return R;
    end; $$;

/*
-- ---------------------------------------------------------------------------------------------------------
create function _VAR_.¶format( ¶template text, variadic ¶values text[] )
  returns text stable strict language plpgsql as $$
  begin
    ¶values :=  array_agg( ¶( key ) ) from unnest( ¶values ) as key;
    return format( ¶template, variadic ¶values );
    end; $$;
*/

-- ---------------------------------------------------------------------------------------------------------
create function _VAR_.¶format( ¶template text, variadic ¶values text[] )
  returns text stable strict language sql as $$
    select format( ¶template, variadic ( select array_agg( ¶( key ) ) from unnest( ¶values ) as key ) );
    $$;

select * from U.variables where key ~ '^intershop' order by key;
select ¶( 'intershop/db/name' );
select _VAR_.¶resolve( 'welcome to ${intershop/db/name} (not \${Lemuria})!!!' );
select _VAR_.¶resolve( '${intershop/db/port}' );
select _VAR_.¶resolve( '${intershop/db/port}${intershop/db/user}' );
select _VAR_.¶resolve( '${intershop/db/port}\${intershop/db/user}' );

select format( 'welcome to %s (not %%sLemuria!!!', 'intershop/db/name' );
select _VAR_.¶format( 'welcome to %s (not %%sLemuria)!!!', 'intershop/db/name' );
-- select _VAR_.¶format( 'connecting to %s:%s', 'intershop/rpc/host', 'intershop/rpc/port' );
-- select format( '${intershop/db/port}' );
-- select format( '${intershop/db/port}${intershop/db/user}' );
-- select format( '${intershop/db/port}\${intershop/db/user}' );



-- \set pwd `pwd`
-- \echo :pwd
\quit

