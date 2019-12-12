


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/INTERSHOP-WRITE-ADDONS-BUILDSCRIPT'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
# resolve_pkg               = require 'resolve-pkg'
# package_json              = require PATH.resolve PATH.join process.env.intershop_host_path, 'package.json'
#...........................................................................................................
types                     = new ( require 'intertype' ).Intertype()
{ isa
  validate
  cast
  check
  declare
  declare_check
  is_sad
  type_of }               = types.export()
#...........................................................................................................
{ jr }                    = CND
squel                     = ( require 'squel' ).useFlavour 'postgres'


#-----------------------------------------------------------------------------------------------------------
@as_line = ( sql ) -> sql.toString() + ';'

#-----------------------------------------------------------------------------------------------------------
@add_addon = ( aoid, path, relpath ) ->
  sql = squel
    .insert().into 'ADDONS.addons'
    .set 'aoid',      aoid
    .set 'path',      path
    .set 'relpath',   relpath
  return @as_line sql

#-----------------------------------------------------------------------------------------------------------
@add_file = ( aoid, target, path, relpath ) ->
  sql = squel
    .insert().into 'ADDONS.files'
    .set 'aoid',      aoid
    .set 'target',    target
    .set 'path',      path
    .set 'relpath',   relpath
  return @as_line sql

#-----------------------------------------------------------------------------------------------------------
@write_buildscript = ( addons ) ->
  validate.object addons
  for addon in addons.addons
    debug '^363673^', addon;
    info '^363674^', addon.module.path;# process.exit 1
    echo()
    echo "# #{'-'.repeat 108}"
    echo "# Addon: #{addon.aoid}"
    echo "# #{addon.module.path}"
    # echo """postgres_unpaged -c "select generate_series( 1, 9 );" """
    for file_id, file of addon.targets
      { target, relpath, abspath, } = file
      switch target
        when 'rebuild'
          ### TAINT must escape critical characters ###
          echo "echo -e $orange$reverse $reset$orange '#{abspath}'$reset"
          echo "postgres_unpaged -f #{abspath}"
        # else
        #   echo "# skipping #{target} file #{abspath}"
  echo "# #{'-'.repeat 108}"
  echo "# (end of addons)"
  echo()
  return null

#-----------------------------------------------------------------------------------------------------------
@write_sql_inserts = ( addons ) ->
  validate.object addons
  FS.writeFileSync addons.populate_sql_path, ''
  #.........................................................................................................
  write = ( x = '' ) ->
    validate.text x
    FS.appendFileSync addons.populate_sql_path, x + '\n'
    return null
  #.........................................................................................................
  write "-- generated by #{__filename}"
  write "-- generated on #{( new Date() ).toString()}"
  write()
  for addon in addons
    write @add_addon aoid, addon.module.path, addon.module.relpath
    for file_id, file of addon.targets
      { target, relpath, abspath, } = file
      write @add_file aoid, target, abspath, relpath
  return null

#-----------------------------------------------------------------------------------------------------------
@generate_scripts = ->
  addons                    = ( require './intershop-find-addons' ).find_addons()
  @write_buildscript addons
  @write_sql_inserts addons
  return null


############################################################################################################
if module is require.main then do =>
  @generate_scripts()



