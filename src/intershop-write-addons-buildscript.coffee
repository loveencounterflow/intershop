


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
  echo()
  echo "##{'-'.repeat 108}"
  echo "# ^#{__filename}/write_buildscript@46576^"
  echo()
  echo "echo -e $orange$reverse $reset$orange '#{addons.populate_sql_path}'$reset"
  echo "postgres_unpaged -f #{addons.populate_sql_path}"
  #.........................................................................................................
  # for aoid, addon of addons.addons
  # debug ( k for k of addons.addons )
  # debug addons.order
  for [ aoid, _, ] in addons.order
    addon = addons.addons[ aoid ]
    echo()
    echo "# #{'-'.repeat 108}"
    echo "# Addon: #{addon.aoid}"
    echo "# #{addon.path}"
    # echo """postgres_unpaged -c "select generate_series( 1, 9 );" """
    for file_id, file of addon.files
      { target, relpath, path, } = file
      switch target
        when 'rebuild'
          ### TAINT must escape critical characters ###
          echo "echo -e $orange$reverse $reset$orange '#{path}'$reset"
          echo "postgres_unpaged -f #{path}"
        # else
        #   echo "# skipping #{target} file #{path}"
  #.........................................................................................................
  # echo "postgres_unpaged -c 'select ADDONS.import_python_addons();'" # not necessary, done by `U.py_init()`
  echo "# #{'-'.repeat 108}"
  echo "# (end of addons)"
  echo()
  return null

#-----------------------------------------------------------------------------------------------------------
@write_summary = ( addons ) ->
  validate.object addons
  validate.nonempty_text bin_path = process.env.intershop_guest_bin_path
  validate.nonempty_text mod_path = process.env.intershop_guest_modules_path
  echo()
  # echo "#{bin_path}/intershop-nodexh #{mod_path}/intershop-find-addons.js"
  echo """echo -e "$steel$reverse" 'ADDONS.files' "$reset\""""
  echo """postgres_unpaged -c 'select aoid, target, relpath from ADDONS.files order by aoid, target, relpath;'"""
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
  for aoid, addon of addons.addons
    write()
    write '-- ' + '_'.repeat 105
    write "-- Addon: #{addon.aoid}"
    write @add_addon addon.aoid, addon.path, addon.relpath
    for file_id, file of addon.files
      { target, relpath, path, } = file
      write @add_file addon.aoid, target, path, relpath
  write()
  write '-- EOF'
  return null

#-----------------------------------------------------------------------------------------------------------
@generate_scripts = ->
  addons = ( require './intershop-find-addons' ).find_addons()
  @write_buildscript  addons
  @write_sql_inserts  addons
  @write_summary      addons
  return null


############################################################################################################
if module is require.main then do =>
  @generate_scripts()



