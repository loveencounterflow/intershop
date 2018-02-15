

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _BENCHMARKS_ cascade;
create schema _BENCHMARKS_;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _BENCHMARKS_.main() returns void language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import sys
  import time
  ctx.log( '33221' )
  #.........................................................................................................
  keys = [ key for key in ctx ]
  keys.sort()
  for key in keys:
    ctx.log( 'ctx.' + key )
  #.........................................................................................................
  def rpc( channel, method, parameters ):
    ctx.signals._send( channel, 'rpc', 'q', { 'method': method, 'parameters': parameters, } )
    return ctx.signals._read_line()
  #.........................................................................................................
  R = rpc( 'mojikura', 'add', [ 42, 108 ] )
  ctx.log( '01129', R )
  #.........................................................................................................
  n = 10000
  t0 = time.time()
  for i in range( 0, n ):
    # R = ctx.rds.rpc( 'add', { 'a': 42, 'b': i, } )
    R = rpc( 'mojikura', 'add', [ 42, i ] )
    # ctx.log( '!!!!!!!!!!!', R )
  t1  = time.time()
  dt  = t1 - t0
  ctx.log( '29091', 'n', n, 'dt', dt )
  xxx
  $$;
reset role;
  -- # ctx.redis.set( 'bar', '\u5fc3' )
-- r.set( 'foo', '心' )

select _BENCHMARKS_.main();
\quit
