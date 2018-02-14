

'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/REDIS'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
REDIS                     = require 'redis'
promisify                 = ( require 'util' ).promisify
jr                        = JSON.stringify

client = REDIS.createClient()

client.on 'error', ( error ) ->
  alert error

client.on 'ready',                    -> urge 'ready'
client.on 'connect',                  -> urge 'connect'
client.on 'reconnecting',             -> urge 'reconnecting'
client.on 'end',                      -> urge 'end'
client.on 'warning',      ( message ) -> urge message

sub         = REDIS.createClient()
pub         = REDIS.createClient()
msg_count   = 0

sub.on 'psubscribe', ( channel, count ) ->
  debug '44921', channel, count
  pub.publish 'intershop/foo', "first message."
  pub.publish 'intershop/foo', jr { foo: "second message.", }
  pub.publish 'intershop/foo', "third message."

sub.on 'pmessage', ( pattern, channel, message ) ->
  info "sub channel #{pattern} -> #{channel}: #{rpr message}"
  if channel == 'intershop/rpc/q'
    value = JSON.parse message
    urge rpr value
    { rpcid, } = value
    rpcid ?= 1 # 'no RPC ID'
    data = value.data ? null
    ### TAINT implement error protocol for requests with unexpected data ###
    pub.publish 'intershop/rpc/a', jr { rpcid, result: ( data.a ? 0 ) + ( data.b ? 0 ), }
  # msg_count += 1
  # if msg_count is 3
  #   sub.unsubscribe()
  #   sub.quit()
  #   pub.quit()

sub.psubscribe 'intershop/*'



