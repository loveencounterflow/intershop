

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
client = REDIS.createClient()


client.on 'error', ( error ) ->
  alert error

client.on 'ready',                    -> urge 'ready'
client.on 'connect',                  -> urge 'connect'
client.on 'reconnecting',             -> urge 'reconnecting'
client.on 'end',                      -> urge 'end'
client.on 'warning',      ( message ) -> urge message


client.set    'string key', 'string val', ( error, reply ) -> throw error if error?; whisper reply
client.hset   'hash key',   'hashtest 1', 'some value', ( error, reply ) -> throw error if error?; whisper reply
client.hset   [ 'hash key', 'hashtest 2', 'some other value', ], ( error, reply ) -> throw error if error?; whisper reply
client.hkeys  'hash key', ( error, replies ) ->
  throw error if error?
  help "#{replies.length} replies:"
  for reply in replies
    info reply
  client.quit()


CND.dir REDIS
CND.dir client