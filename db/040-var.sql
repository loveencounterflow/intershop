

/*

 .d88888b.  888      8888888b.
d88P" "Y88b 888      888  "Y88b
888     888 888      888    888
888     888 888      888    888
888     888 888      888    888
888     888 888      888    888
Y88b. .d88P 888      888  .d88P
 "Y88888P"  88888888 8888888P"

*/



-- =========================================================================================================
-- VARIABLES
-- ---------------------------------------------------------------------------------------------------------
create table U.variables of U.text_facet ( key unique not null primary key );

-- ---------------------------------------------------------------------------------------------------------
create function ¶( ¶key text ) returns text stable language plpgsql as $$
  declare
    ¶row_count  integer;
    R           text;
  begin
    R := value from U.variables where key = ¶key;
    get diagnostics ¶row_count = row_count;
    if ¶row_count != 1 then raise exception 'variable not found: %', $1; end if;
    return R;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.set_default( ¶key text, ¶value text ) returns boolean volatile language plpgsql as $$
  declare
    ¶row_count  integer;
  begin
    insert into U.variables values ( ¶key, ¶value )
      on conflict ( key ) do nothing;
    get diagnostics ¶row_count = row_count;
    if ¶row_count != 1 then return true; else return false; end if;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function ¶( ¶key text, ¶value anyelement ) returns void volatile language sql as $$
  insert into U.variables values ( ¶key, ¶value )
  on conflict ( key ) do update set value = ¶value; $$;

-- ---------------------------------------------------------------------------------------------------------
/* Like standard `format` function, but uses *names* in `U.variables` instead of literals to perform
  interpolation; e.g. `select ¶format( 'connecting to %s:%s', 'intershop/rpc/host', 'intershop/rpc/port' );`
  might give you `'connecting to 127.0.0.1:23001'`. Equivalent to `format( '...%s...', ¶( 'key' ) )`. */
create function ¶format( ¶template text, variadic ¶values text[] )
  returns text stable strict language sql as $$
    select format( ¶template, variadic ( select array_agg( ¶( key ) ) from unnest( ¶values ) as key ) ); $$;

/*
create function ¶format( ¶template text, variadic ¶values text[] )
  returns text stable strict language plpgsql as $$
  begin
    ¶values :=  array_agg( ¶( key ) ) from unnest( ¶values ) as key;
    return format( ¶template, variadic ¶values );
    end; $$;
*/


-- =========================================================================================================
-- NODEJS
-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U._nodejs_versions() returns jsonb volatile language plsh as $$#!/usr/local/bin/node
  console.log( JSON.stringify( process.versions ) ); $$;
  -- R = ( { key: value, } for key, value of process.versions )
  -- $$#!/usr/local/bin/coffee
  --   console.log 'helo'
  --   $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
create materialized view U.nodejs_versions as (
  select * from jsonb_each_text( U._nodejs_versions() ) );

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U._get_hostname() returns text language plpython3u as $$
  import socket as _SOCKET; return _SOCKET.gethostname() $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U._get_architecture_etc() returns jsonb volatile language plsh as $$#!/usr/local/bin/node
  console.log( JSON.stringify( {
    architecture: process.arch,
    platform:     process.platform,
    } ) ); $$;
reset role;


-- =========================================================================================================
-- ABSORB OS ENVIRONMENT
-- -- ---------------------------------------------------------------------------------------------------------
-- create function OS.is_dev() returns boolean volatile language sql as $$
--   select ¶( 'os/env/NODE_ENV' ) = 'dev'; $$;

-- ---------------------------------------------------------------------------------------------------------
create function U._set_env_variable( ¶key text, ¶value text ) returns void volatile language sql as $$
  select ¶( 'os/env/' || ¶key, ¶value ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function U._get_env_variable( ¶key text ) returns text stable language sql as $$
  select ¶( 'os/env/' || ¶key ); $$;

-- ---------------------------------------------------------------------------------------------------------
-- UPDATE VARIABLES
-- ---------------------------------------------------------------------------------------------------------
\ir './update-os-env.sql'
\quit




