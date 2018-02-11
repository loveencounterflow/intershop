

/*

 .d88888b.    .d8888b.
d88P" "Y88b  d88P  Y88b
888     888  Y88b.
888     888   "Y888b.
888     888      "Y88b.
888     888        "888
Y88b. .d88P  Y88b  d88P
 "Y88888P"    "Y8888P"

*/


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists OS cascade;
create schema OS;


-- =========================================================================================================
-- NODEJS
-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function OS._nodejs_versions() returns jsonb volatile language plsh as $$#!/usr/local/bin/node
  console.log( JSON.stringify( process.versions ) ); $$;
  -- R = ( { key: value, } for key, value of process.versions )
  -- $$#!/usr/local/bin/coffee
  --   console.log 'helo'
  --   $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
create materialized view OS.nodejs_versions as (
  select * from jsonb_each_text( OS._nodejs_versions() ) );

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function OS._get_hostname() returns text language plpython3u as $$
  import socket as _SOCKET; return _SOCKET.gethostname() $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function OS._get_architecture_etc() returns jsonb volatile language plsh as $$#!/usr/local/bin/node
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
create function OS._set_env_variable( ¶key text, ¶value text ) returns void volatile language sql as $$
  select ¶( 'os/env/' || ¶key, substring( ¶value for 50 ) ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function OS._get_env_variable( ¶key text ) returns text stable language sql as $$
  select ¶( 'os/env/' || ¶key ); $$;

-- ---------------------------------------------------------------------------------------------------------
\ir './update-os-env.sql'

-- \set pwd `pwd`
-- \echo :pwd
\quit

