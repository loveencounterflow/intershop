

-- \set ECHO queries

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
begin transaction;

\set filename interplot/db/experiments/plpython-redirect-stdout.sql
\set signal :red

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade; create schema X;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function X.print() returns void volatile language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  print( 'helo', 42, 'world' )
  print( 'printing\nout\na\nfew\nlines\n' )
  print( list( k for k in dir( ctx ) if not k.startswith( '_' ) ) )
  ctx.log( "and yet another" )
  ctx.log( "and yet another" )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
do $$ begin perform X.print(); end; $$;


/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function X._redirect_stdout() returns void volatile language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import sys
  import re
  #.........................................................................................................
  class Redirector:
    #.......................................................................................................
    def __init__( me ):
      me.buffer = []
    #.......................................................................................................
    def pen( me, *P ):
      R = ''
      for p in P:
        if not isinstance( p, str ): p = str( p )
        R += p
      return R
    #.......................................................................................................
    def write( me, message ): me._write( me.pen( message ) )
    #.......................................................................................................
    def _write( me, text ):
      for part in re.split( '(\n)', text ):
        if part == '\n':
          plpy.notice( ''.join( me.buffer ) )
          me.buffer.clear()
        else:
          me.buffer.append( part )
  #.........................................................................................................
  redirector            = Redirector()
  ctx._original_stdout  = sys.stdout
  sys.stdout            = redirector
  if ctx.get( 'log', None ) == None:
    ctx.log = lambda *P: redirector._write( redirector.pen( *P, '\n' ) )
  $$;
reset role;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
do $$ begin perform X._redirect_stdout(); end; $$;
do $$ begin perform X.print(); end; $$;





/* ###################################################################################################### */
\echo :red ———{ :filename 7 }———:reset
\quit






