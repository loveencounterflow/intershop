



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/RPC/PRIMARY'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
### https://github.com/mafintosh/respawn ###
respawn                   = require 'respawn'
#...........................................................................................................
require 'cnd/lib/exception-handler'
O                         = require './options'

monitor = respawn O.respawn
monitor.on 'crash',   ( data ) -> urge 'crash',   '>>>>>>>>>>>', "The monitor has crashed (too many restarts or spawn error)."
monitor.on 'sleep',   ( data ) -> urge 'sleep',   '>>>>>>>>>>>', "monitor is sleeping"
monitor.on 'spawn',   ( data ) -> urge 'spawn',   '>>>>>>>>>>>', "New child process has been spawned"
monitor.on 'start',   ( data ) -> urge 'start',   '>>>>>>>>>>>', "The monitor has started"
monitor.on 'stderr',  ( data ) -> urge 'stderr',  '>>>>>>>>>>>', "child process stderr has emitted data"; whisper data
monitor.on 'stdout',  ( data ) -> urge 'stdout',  '>>>>>>>>>>>', "child process stdout has emitted data"; whisper data
monitor.on 'stop',    ( data ) -> urge 'stop',    '>>>>>>>>>>>', "The monitor has fully stopped and the process is killed"
monitor.on 'warn',    ( data ) -> urge 'warn',    '>>>>>>>>>>>', "child process has emitted an error"; warn data

#-----------------------------------------------------------------------------------------------------------
monitor.on 'exit', ( code, signal ) ->
  urge 'exit', '>>>>>>>>>>>', "child process has exited with code #{rpr code}, signal #{rpr signal}"
  if code isnt 0
    urge "terminating RPC server primary"
    process.exit code

#-----------------------------------------------------------------------------------------------------------
monitor.on 'message', ( message ) ->
  urge "received message: #{rpr message}"
  switch message
    when 'stop'
      warn "terminating"
      process.exit 0
    else
      warn "unknown message; ignoring"
  return null

############################################################################################################
monitor.start()












