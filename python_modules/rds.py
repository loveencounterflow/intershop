
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
  ctx.log( '28882', repr( message ) )
  # xxx_log( '28882', repr( data.get( 'data' ) ) )
  try:
    if message.get( 'type' ) != 'message': return
    data = message.get( 'data' )
    if data == None: return
    data = _JSON.loads( data )
    if not hasattr( data, 'get' ): return
    rpcid = data.get( 'rpcid' )
    if rpcid is None: return
    rpc_results[ rpcid ] = data
  except Exception:
    raise

#-----------------------------------------------------------------------------------------------------------
def get_rpc_a( rpcid ):
  R     = None
  delta = 1 / 4
  count = 0
  while True:
    count += +delta
    if count > 1: break
    rpc_a_listener.get_message()
    ctx.log( '77621', rpc_results )
    R = rpc_results.get( rpcid )
    _TIME.sleep( delta )
  return R

#-----------------------------------------------------------------------------------------------------------
rpc_a_listener  = new_redis().pubsub( ignore_subscribe_messages = True )
rpc_a_listener.subscribe( **{ 'intershop/rpc/a': _on_rpc_a, } )
# # throw away subscription message:
# rpc_a_listener.get_message()
# r = _REDIS.StrictRedis( host = 'localhost', port = 6379, db = 0 )
# print( r.get( 'foo' ) )

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

  # for rsp in rpc_a_listener.listen():
  #   break
    # try:
    #   # value = _JSON.loads( rsp )
    #   if rsp.get( 'rpcid' ) == rpcid:
    #     break
    # except Exception as e:
    #   raise





