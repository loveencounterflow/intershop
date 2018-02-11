
-- =========================================================================================================
-- VARIABLES
-- ---------------------------------------------------------------------------------------------------------
create table U.variables of U.text_facet ( key unique not null primary key );

-- ---------------------------------------------------------------------------------------------------------
drop function if exists ¶( text ) cascade;
create function ¶( ¶key text ) returns text volatile language sql as $$
  select value from U.variables where key = ¶key; $$;

-- ---------------------------------------------------------------------------------------------------------
drop function if exists ¶( text, anyelement ) cascade;
create function ¶( ¶key text, ¶value anyelement ) returns void volatile language sql as $$
  insert into U.variables values ( ¶key, ¶value )
  on conflict ( key ) do update set value = ¶value; $$;


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
  select ¶( 'os/env/' || ¶key, substring( ¶value for 50 ) ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function U._get_env_variable( ¶key text ) returns text stable language sql as $$
  select ¶( 'os/env/' || ¶key ); $$;

-- ---------------------------------------------------------------------------------------------------------
\ir './update-os-env.sql'

-- \set pwd `pwd`
-- \echo :pwd
\quit

