

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/intershop-reconstruct'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',     badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
SHELL                     = require 'shelljs'
FS                        = require 'fs'
PATH                      = require 'path'
is_executable             = require 'executable'

### TAINT using environment instead of values from intershop.ptv ###
### TAINT values from intershop.ptv do not include intershop/guest/bin/path ###

#-----------------------------------------------------------------------------------------------------------
E = {}
for key, value of process.env
  continue unless key.startsWith 'intershop'
  E[ key ] = value
# for key in ( Object.keys E ).sort()
#   debug '27772', ( CND.blue key ), ( CND.white E[ key ] )

#-----------------------------------------------------------------------------------------------------------
S = {}
[ _, _, S.first_module_nr, S.last_module_nr, ] = process.argv

#-----------------------------------------------------------------------------------------------------------
if ( S.first_module_nr?= '000' )?
  unless ( S.first_module_nr.match /^[0-9]{3}$/ )?
    throw new Error "expected a three-digit number to identify first module, got #{rpr S.first_module_nr}"

#-----------------------------------------------------------------------------------------------------------
if ( S.last_module_nr?= null )?
  unless ( S.last_module_nr.match /^[0-9]{3}$/ )?
    throw new Error "expected a three-digit number to identify last module, got #{rpr S.last_module_nr}"

#-----------------------------------------------------------------------------------------------------------
psql_f              = "#{E.intershop_guest_bin_path}/intershop-psql -f"
psql_c              = "#{E.intershop_guest_bin_path}/intershop-psql -c"
# rec_prep_path       = "#{E.intershop_host_sql_path}/intershop-reconstruct-prepare.sql"
SHELL.config.silent = false
SHELL.config.fatal  = true

#-----------------------------------------------------------------------------------------------------------
extension_from_path = ( path ) ->
  return PATH.extname path

#-----------------------------------------------------------------------------------------------------------
get_type_of_buildfile = ( path ) ->
  return 'executable' if await is_executable path
  return extension_from_path path

#-----------------------------------------------------------------------------------------------------------
do ->
  # SHELL.exec "#{psql_f} '#{rec_prep_path}'"
  skipped = []
  #.........................................................................................................
  flush = ->
    if skipped.length > 0
      whisper "skipped #{skipped.join ', '}"
      skipped.length = 0
    return null
  #.........................................................................................................
  for path in SHELL.ls "#{E.intershop_host_sql_path}/[0-9][0-9][0-9]-*"
    cwd         = FS.realpathSync process.cwd()
    path        = FS.realpathSync path
    relpath     = PATH.relative cwd, path
    filename    = PATH.basename path
    filetype    = await get_type_of_buildfile path
    # module_nr   = ( filename.replace /^([-0-9]+).*$/, '$1' ).replace /-+$/, ''
    module_nr   = filename.replace /^([0-9]+).*$/, '$1'
    #.......................................................................................................
    if module_nr < S.first_module_nr
      # whisper "skipping #{relpath}"
      skipped.push module_nr
      continue
    #.......................................................................................................
    if S.last_module_nr? and module_nr > S.last_module_nr
      # whisper "skipping #{relpath}"
      skipped.push module_nr
      continue
    #.......................................................................................................
    flush()
    urge '^22231^', ( CND.reverse ' ' ), relpath
    #.......................................................................................................
    switch filetype
      when 'executable'
        SHELL.exec path
      when '.sql'
        whisper '^22232^', "#{psql_f} '#{path}'"
        SHELL.exec "#{psql_f} '#{path}'"
      else
        throw new Error "unrecognized filetype of #{path}:\n#{filetype}"
  #.........................................................................................................
  flush()
  return null

# SHELL.exec( """#{E.intershop_guest_bin_path}/intershop-psql -c "select * from U.variables where key ~ '^intershop'" """ )

############################################################################################################
unless module.parent?
  null
# debug '73833', S
# process.exit 1



