

/* ###################################################################################################### */
\ir './010-trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- \set signal :green
-- \echo :signal ———{ :filename 1 }———:reset
\set filename 090-addons.sql
-- -- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists ADDONS cascade;
create schema ADDONS;

-- ---------------------------------------------------------------------------------------------------------
-- ### NOTE this is a very restrictive definition of what addon names may look like, but we can always
-- relax the constraints later on: ###
create domain ADDONS._aoid as text check ( value ~ '^[-_a-z0-9/]+$' );
create domain ADDONS._path as text check ( value ~ '.+' );

-- ---------------------------------------------------------------------------------------------------------
create table ADDONS.targets (
  target  text unique not null primary key,
  comment text not null );

insert into ADDONS.targets values
  ( 'app',      'Source file required by NodeJS application code'     ),
  ( 'rpc',      'JS file that exports RPC methods'                    ),
  ( 'ignore',   'Source file managed by user'                         ),
  ( 'support',  'Supporting library functions written in plPython3u'  ),
  ( 'rebuild',  'SQL file to be read during rebuilds'                 );

-- ---------------------------------------------------------------------------------------------------------
create table ADDONS.addons (
  aoid    ADDONS._aoid unique not null primary key,
  path    text unique not null,
  relpath text unique not null );

-- ---------------------------------------------------------------------------------------------------------
create table ADDONS.files (
  aoid     ADDONS._aoid not null references ADDONS.addons ( aoid ),
  target  text not null references ADDONS.targets ( target ),
  path    text not null,
  relpath text not null,
  primary key ( aoid, path ) );

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function ADDONS.import_python_addons() returns void language plpython3u as $$
  import os.path
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  #.........................................................................................................
  sql   = """
    select
        aoid,
        target,
        path
      from ADDONS.files
      where target = 'support'
      order by aoid, path;"""
  plan  = plpy.prepare( sql )
  rows  = plpy.execute( plan )
  for row in rows:
    # ctx[ row[ 'key' ] ] = row[ 'value' ]
    file_name                   = os.path.basename( row[ 'path' ] )
    module_name                 = "{}/{}".format( row[ 'aoid' ], file_name )
    ctx.log( '^intershop/026-addons@5554^', "importing {} as ctx.addons[ {} ]".format( row[ 'path' ], repr( module_name ) ) )
    module                      = ctx.module_from_path( ctx, module_name, row[ 'path' ] )
    ctx.addons[ module_name ]   = module
    preparer                    = getattr( module, '_prepare', None )
    if preparer is not None:
      preparer( ctx )
  #.........................................................................................................
  ### TAINT use dedicated function to set variable ###
  sql = """select ¶( 'intershop/addons/loaded', 'true'::text );"""
  plan  = plpy.prepare( sql )
  rows  = plpy.execute( plan )
  $$;
reset role;



/* ###################################################################################################### */
\echo :red ———{ :filename 2 }———:reset
\quit

