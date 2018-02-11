

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
    ctx.python_path       = ctx.get_variable( 'intershop/paths/python_modules'  )
    ctx.psql_output_path  = ctx.get_variable( 'intershop/paths/psql_output'     )
    sys.path.insert( 0, ctx.python_path )
    #.......................................................................................................
    def log( *P ):
      R = []
      for p in P:
        if isinstance( p, str ):  R.append( p )
        else:                     R.append( repr( p ) )
      R = ' '.join( R )
      with open( ctx.psql_output_path, 'ab' ) as o:
        o.write( R.encode( 'utf-8' ) + b'\n' )
      return R
    #.......................................................................................................
    ctx.log = log
    #.......................................................................................................
    import intershop_main
    intershop_main.setup( ctx )
    #.......................................................................................................
    $$;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
drop function if exists log( variadic text[] ) cascade;
create function log( value variadic text[] ) returns void language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  value_ = [ str( e ) for e in value ]
  with open( ctx.psql_output_path, 'ab' ) as o:
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
create function U._test_py_init() returns void language plpython3u as $$
  plpy.execute( 'select U.py_init()' )
  ctx = GD[ 'ctx' ]
  import sys
  for idx, path in enumerate( sys.path ):
    ctx.log( idx + 1, path )
  # ctx.log( ctx )
  ctx.log( "U.py_init OK" )
  import signals
  ctx.log( 'signals', signals )
  ctx.log( ctx.url_parser )
  $$;
reset role;



/* ###################################################################################################### */

do $$ begin perform U._test_py_init(); end; $$;
do $$ begin perform log( 'using log function OK' ); end; $$;

\quit






