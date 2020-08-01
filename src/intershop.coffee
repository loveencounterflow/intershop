

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
MAIN                      = @
@types                    = require './types'
{ validate
  isa }                   = @types.export()

#-----------------------------------------------------------------------------------------------------------
@get = ( key ) ->
  unless ( entry = @settings[ key ] )?
    throw new Error "^intershop/get@44787^ unknown variable #{rpr key}"
  { type, value, } = entry
  switch type
    when 'int', 'integer'
      validate.integer R = parseInt value, 10
    when 'U.natural_number'
      validate.positive_integer R = parseInt value, 10
    when 'text'               then R = value
    when 'json'               then R = JSON.parse value
    when 'boolean'
      if      value is 'true'  then R = true
      else if value is 'false' then R = false
      else throw new Error "^intershop/get@44787^ expected a boolean literal, got #{rpr value}"
    else R = value
    # when 'url'
    # text/path/folder
    # url
    # text/ip-address
    # unit
    # text/path/file
  return R

#-----------------------------------------------------------------------------------------------------------
### TAINT consider to use Multimix ###
@new_intershop = ( path = null ) ->
  R               = {}
  R.PTV_READER    = require './ptv-reader'
  R.new_intershop = MAIN.new_intershop.bind MAIN
  R.types         = MAIN.types
  R.get           = MAIN.get.bind R
  #.........................................................................................................
  ### TAINT validate ###
  intershop_host_path                 = path ? process.env[ 'intershop_host_path' ] ? process.cwd()
  intershop_guest_path                = resolve join intershop_host_path,  'intershop'
  intershop_host_configuration_path   = resolve join intershop_host_path,  'intershop.ptv'
  intershop_guest_configuration_path  = resolve join intershop_guest_path, 'intershop.ptv'
  #.........................................................................................................
  R.settings                                         = {}
  R.settings[ 'intershop/host/path'                ] = { type: 'text/path/folder', value: intershop_host_path, }
  R.settings[ 'intershop/guest/path'               ] = { type: 'text/path/folder', value: intershop_guest_path, }
  R.settings[ 'intershop/host/configuration/path'  ] = { type: 'text/path/folder', value: intershop_host_configuration_path, }
  R.settings[ 'intershop/guest/configuration/path' ] = { type: 'text/path/folder', value: intershop_guest_configuration_path, }
  R.settings[ "os/env/#{key}"                      ] = { type: 'text', value, } for key, value of process.env
  #.........................................................................................................
  try
    R.PTV_READER.update_hash_from_path intershop_guest_configuration_path, R.settings
  catch error
    warn """
      '^intershop@334-1^'
      when trying to read guest configuration from
        #{intershop_guest_configuration_path}
      an error occurred:
        #{error.message}"""
    # process.exit 1
    # throw error
  try
    R.PTV_READER.update_hash_from_path intershop_host_configuration_path,  R.settings
  catch error
    warn """
      '^intershop@334-2^'
      when trying to read host configuration from
        #{intershop_host_configuration_path}
      an error occurred:
        #{error.message}"""
    process.exit 1
    throw error
  #.........................................................................................................
  return R


