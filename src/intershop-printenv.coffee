
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
### https://github.com/felixge/bash ###
BASH                      = require 'bash'
#...........................................................................................................
O                         = require './options'


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
      # name_rpr  = 'intershop_' + ( BASH.escape k for k in stack ).join '_'
      # value_rpr = BASH.escape value
      # R.push "#{name_rpr}=#{value_rpr}"
      R.push "intershop_#{stack.join '_'}='#{value}'"
    stack.pop()
  return R


############################################################################################################
do ->
  echo entry for entry in get_all_entries O




