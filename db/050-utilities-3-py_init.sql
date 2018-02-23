

/*

                             d8b          d8b 888
                             Y8P          Y8P 888
                                              888
88888b.  888  888            888 88888b.  888 888888
888 "88b 888  888            888 888 "88b 888 888
888  888 888  888            888 888  888 888 888
888 d88P Y88b 888            888 888  888 888 Y88b.
88888P"   "Y88888  88888888  888 888  888 888  "Y888
888           888
888      Y8b d88P
888       "Y88P"

*/

-- select * from U.variables order by key;
-- select * from U.variables where key ~ 'intershop' order by key;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U.py_init() returns void language plpython3u as $$
    if 'ctx' in GD: return
    import sys
    import os
    from pathlib import Path
    #.......................................................................................................
    # https://stackoverflow.com/a/29548234
    # https://stackoverflow.com/a/29548234/7568091
    class AttributeDict(dict):
      def __getattr__(self, attr):
        return self[attr]
      def __setattr__(self, attr, value):
        self[attr] = value
    #.......................................................................................................
    ctx           = AttributeDict()
    target        = AttributeDict()
    GD[ 'ctx' ]   = ctx
    ctx.plpy      = plpy
    ctx.execute   = plpy.execute
    ctx.notice    = plpy.notice
    #.......................................................................................................
    def get_variable( key ):
      sql   = """select ¶( $1 ) as value"""
      plan  = plpy.prepare( sql, [ 'text', ] )
      rows  = plpy.execute( plan, [ key, ] )
      if len( rows ) != 1:
        raise Exception( "unable to find setting " + repr( key ) + " in U.variables" )
      return rows[ 0 ][ 'value' ]
    #.......................................................................................................
    def set_variable( key, value ):
      sql   = """select ¶( $1, $2 )"""
      plan  = plpy.prepare( sql, [ 'void', ] )
      rows  = plpy.execute( plan, [ key, value, ] )
    #.......................................................................................................
    ctx.get_variable = get_variable
    ctx.set_variable = set_variable
    #.......................................................................................................
    def _absorb_environment( ctx ):
      sql   = """
        select regexp_replace( key, '/', '_', 'g' ) as key, value
          from U.variables where key ~ '^intershop/';"""
      plan  = plpy.prepare( sql )
      rows  = plpy.execute( plan )
      for row in rows:
        ctx[ row[ 'key' ] ] = row[ 'value' ]
      ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
      ### TAINT for the moment we manually cast some values:
      ctx.intershop_rpc_port = int( ctx.intershop_rpc_port )
      ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
    #.......................................................................................................
    ### TAINT some variables will have wrong type (stringly typed enviroment variables) ###
    _absorb_environment( ctx )
    #.......................................................................................................
    if ctx.intershop_host_modules_path != ctx.intershop_guest_modules_path:
      sys.path.insert( 0, ctx.intershop_host_modules_path )
    sys.path.insert( 0, ctx.intershop_guest_modules_path )
    #.......................................................................................................
    def log( *P ):
      R = []
      for p in P:
        if isinstance( p, str ):  R.append( p )
        else:                     R.append( repr( p ) )
      R = ' '.join( R )
      with open( ctx.intershop_psql_output_path, 'ab' ) as o:
        o.write( R.encode( 'utf-8' ) + b'\n' )
      return R
    #.......................................................................................................
    def log_python_path():
      ctx.log( "- - - - - ---------===(0)===--------- - - - - -"  )
      ctx.log( "Python path:" )
      for idx, path in enumerate( sys.path ):
        ctx.log( idx + 1, path )
      ctx.log( "- - - - - ---------===(0)===--------- - - - - -"  )
    #.......................................................................................................
    ctx.log                 = log
    ctx.log_python_path     = log_python_path
    ctx._absorb_environment = _absorb_environment
    #.......................................................................................................
    try:
      import intershop_main
    except ImportError:
      log( "Unable to locate module `intershop_main`")
      ctx.log_python_path()
      raise
    intershop_main.setup( ctx )
    #.......................................................................................................
    $$;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
drop function if exists log( variadic text[] ) cascade;
create function log( value variadic text[] ) returns void language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  value_ = [ str( e ) for e in value ]
  with open( ctx.intershop_psql_output_path, 'ab' ) as o:
    o.write( ' '.join( value_ ).encode( 'utf-8' ) + b'\n' )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
create function log() returns void language sql as $$ select log( '' ); $$;

/* use log like so:
do $$ begin perform log( ( 42 + 108 )::text ); end; $$;
*/

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U._benchmark_rpc() returns void language plpython3u as $$
  import time
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  n = 10000
  t0 = time.time()
  for i in range( 0, n ):
    R = ctx.ipc.rpc( 'add', [ 42, i, ] )
    # ctx.log( '!!!!!!!!!!!', R )
  t1  = time.time()
  dt  = t1 - t0
  ctx.log( '29091', 'n', n, 'dt', dt )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U._test_py_init() returns void language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import sys
  ctx.log( ctx.url_parser )
  ctx.log_python_path()
  keys = [ key for key in ctx ]
  keys.sort()
  for key in keys:
    ctx.log( 'ctx.' + key )
  for key in dir( ctx.ipc ):
    # if key.startswith( '_' ): continue
    ctx.log( 'ctx.ipc.' + key )
  for i in range( 0, 3 ):
    ctx.log( '87321', 'RPC result:', repr( ctx.ipc.rpc( 'add', [ 42, i, ] ) ) )
  $$;
reset role;


/* ###################################################################################################### */

-- select * from U.variables where key ~ 'intershop' order by key;
do $$ begin perform U._test_py_init(); end; $$;
-- do $$ begin perform U._benchmark_rpc(); end; $$;
do $$ begin perform log( 'using log function OK' ); end; $$;

\quit






