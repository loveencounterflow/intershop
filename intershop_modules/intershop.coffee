

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
join                      = PATH.join.bind PATH
resolve                   = PATH.resolve.bind PATH
@PTV_READER               = require './ptv-reader'

debug '55633', process.cwd()

intershop_host_path                 = process.cwd()
intershop_guest_path                = resolve join intershop_host_path,  'intershop'
intershop_host_configuration_path   = resolve join intershop_host_path,  'intershop.ptv'
intershop_guest_configuration_path  = resolve join intershop_guest_path, 'intershop.ptv'

urge '44584', 'intershop_host_path                 ', intershop_host_path
urge '44584', 'intershop_guest_path                ', intershop_guest_path
urge '44584', 'intershop_host_configuration_path   ', intershop_host_configuration_path
urge '44584', 'intershop_guest_configuration_path  ', intershop_guest_configuration_path

host_path                 = PATH.resolve PATH.join __dirname, '../..'
guest_configuration_path  = PATH.resolve PATH.join host_path, 'intershop/intershop.ptv'
host_configuration_path   = PATH.resolve PATH.join host_path, 'intershop.ptv'

debug '33421', 'host_path:                ', host_path
debug '33421', 'guest_configuration_path: ', guest_configuration_path
debug '33421', 'host_configuration_path:  ', host_configuration_path

process.exit 1
O                         =
  'intershop/host/path':               { type: 'text', value: host_path,                }
  'intershop/host/configuration/path': { type: 'text', value: host_configuration_path,  }
O                         = @PTV_READER.update_hash_from_path guest_configuration_path, O
O                         = @PTV_READER.update_hash_from_path host_configuration_path,  O


############################################################################################################
unless module.parent?
  INTERSHOP = @
  # INTERSHOP.helo()

