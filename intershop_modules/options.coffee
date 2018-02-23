


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/OPTIONS'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND

# for key, value of process.env
#   continue unless key.startsWith 'intershop_'
#   debug '55762', key, value

#-----------------------------------------------------------------------------------------------------------
ms_from_s_literal = ( s_literal ) ->
  unless ( match = s_literal.match /^([0-9]+)\s*s$/ )?
    throw new Error "unrecognized literal for unit conversion: #{rpr s_literal}"
  return ( parseInt match[ 1 ], 10 ) * 1000

#-----------------------------------------------------------------------------------------------------------
app =
  name:          process.env.intershop_app_name

#-----------------------------------------------------------------------------------------------------------
rpc =
  host:          process.env.intershop_rpc_host
  port: parseInt process.env.intershop_rpc_port, 10

#-----------------------------------------------------------------------------------------------------------
### TAINT use type information in *.ptv file to do conversions ###
### TAINT any of these settings could be missing (shouldn't happen as they are in defaults, but still ) ###
respawn =
  cwd:                            process.env.intershop_rpc_respawn_cwd
  fork:                           process.env.intershop_rpc_respawn_fork is 'true'
  maxRestarts:  parseInt          process.env.intershop_rpc_respawn_maxRestarts, 10
  command:      JSON.parse        process.env.intershop_rpc_respawn_command
  env:          JSON.parse        process.env.intershop_rpc_respawn_env
  name:                           process.env.intershop_rpc_respawn_name
  kill:         ms_from_s_literal process.env.intershop_rpc_respawn_kill
  sleep:        ms_from_s_literal process.env.intershop_rpc_respawn_sleep

module.exports = { app, rpc, respawn, }



