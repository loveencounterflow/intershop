
# -*- coding: utf-8 -*-


############################################################################################################
import time   as _TIME
import json   as _JSON
import redis  as _REDIS

#-----------------------------------------------------------------------------------------------------------
def new_redis():
  return _REDIS.StrictRedis( host = 'localhost', port = 6379, db = 0, decode_responses = True )

#-----------------------------------------------------------------------------------------------------------
last_rpcid      = 0
r               = new_redis()
rpc_results     = {}
implicit        = {}

#-----------------------------------------------------------------------------------------------------------
def _on_rpc_a( message ):
  # ctx.log( '28882', repr( message ) )
  try:
    if message.get( 'type' ) != 'message': return
    data = message.get( 'data' )
    if data == None: return
    data = _JSON.loads( data )
    if not hasattr( data, 'get' ): return
    rpcid = data.get( 'rpcid' )
    if rpcid is None: return
    rpc_results[ rpcid ] = data.get( 'result' )
  except Exception:
    raise

delta   = 1 / 10000
#-----------------------------------------------------------------------------------------------------------
def get_rpc_a( rpcid ):
  R       = None
  pdt     = 0 # pseudo delta-time (in seconds)
  timeout = 1
  while True:
    R = rpc_results.get( rpcid )
    if R is not None:
      del rpc_results[ rpcid ]
      break
    pdt += +delta
    if pdt > timeout: break
    _TIME.sleep( delta )
  return R

#-----------------------------------------------------------------------------------------------------------
rpc_a_listener  = new_redis().pubsub( ignore_subscribe_messages = True )
rpc_a_listener.subscribe( **{ 'intershop/rpc/a': _on_rpc_a, } )
thread = rpc_a_listener.run_in_thread( sleep_time = delta )
# # throw away subscription message:
# rpc_a_listener.get_message()

#-----------------------------------------------------------------------------------------------------------
def set( key, value ):
  r.set( key, value )

#-----------------------------------------------------------------------------------------------------------
def get( key, value ):
  r.get( key, value )

#-----------------------------------------------------------------------------------------------------------
def publish( channel, value ):
  r.publish( channel, value )
  # pubsub.execute_command( 'publish', channel, value )

#-----------------------------------------------------------------------------------------------------------
def rpc( command, data ):
  global last_rpcid
  last_rpcid += 1
  rpcid       = last_rpcid
  publish( 'intershop/rpc/q', _JSON.dumps( { 'command': command, 'rpcid': rpcid, 'data': data, } ) )
  # ctx.log( '77621', rpc_a_listener.get_message() )
  return get_rpc_a( rpcid )


