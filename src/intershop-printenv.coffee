
###

This script echoes the configuration in Bash format so shellscripts can pick it up.

###

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/MAIN'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo
#...........................................................................................................
BASH                      = require 'bash'
#...........................................................................................................
defaults =
  app:
    name: 'intershop'
  db:
    port: 5433
    name: 'intershop'
    user: 'intershop'
  rpc:
    port: 22222
    host: 'localhost'


#-----------------------------------------------------------------------------------------------------------
get_all_entries = ( x ) -> _get_all_entries x, []

#-----------------------------------------------------------------------------------------------------------
_get_all_entries = ( x, stack ) ->
  R = []
  for key in Object.getOwnPropertyNames x
    continue if key in [ 'config', 'configs', '_', ]
    stack.push key
    value = x[ key ]
    if CND.isa_pod value
      R = [ R..., ( _get_all_entries value, stack )..., ]
    else
      name_rpr  = 'intershop_' + ( BASH.escape k for k in stack ).join '_'
      value_rpr = BASH.escape value
      R.push "#{name_rpr}=#{value_rpr}"
    stack.pop()
  return R


############################################################################################################
C = ( require 'rc') 'intershop', defaults
echo entry for entry in get_all_entries C


