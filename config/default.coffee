
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
config                    = require 'config'


#-----------------------------------------------------------------------------------------------------------
module.exports =

  #.........................................................................................................
  app:
    name:   'intershop'

  #.........................................................................................................
  db:
    port:     5433
    name:     'intershop'
    user:     'intershop'





