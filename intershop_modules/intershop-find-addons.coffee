


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/FIND-ADDONS'
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
resolve_pkg               = require 'resolve-pkg'
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
DATOM                     = require 'datom'
{ new_datom }             = DATOM.export()
#...........................................................................................................
{ jr }                    = CND

#-----------------------------------------------------------------------------------------------------------
declare 'ishop_addon_target', ( x ) -> x in [ 'app', 'ignore', 'support', 'rebuild', ]

#-----------------------------------------------------------------------------------------------------------
@validate_ipj_targets = ( addon ) ->
  #.........................................................................................................
  unless ( type = type_of addon.files ) is 'object' then throw new Error \
    "^intershop/find-addons@478^ expected #{addon.ipj.relpath}#targets to be an object, found #{type}"
  #.........................................................................................................
  if ( isa.empty Object.keys addon.files ) then throw new Error \
    "^intershop/find-addons@478^ #{addon.ipj.relpath}#targets has no keys"
  #.........................................................................................................
  for file_id, { path, relpath, target, } of addon.files
    if is_sad check.is_file path
      throw new Error """^intershop/find-addons@478^
      file #{rpr path}
      referred to in targets[ #{rpr file_id} ]
      of #{addon.ipj.relpath}
      does not exist"""
    unless isa.ishop_addon_target target then throw new Error \
      "^intershop/find-addons@478^ unknown target #{rpr target} in #{addon.ipj.relpath}#targets[ #{rpr file_id} ]"
  #.........................................................................................................
  return true

#-----------------------------------------------------------------------------------------------------------
@find_addons = ->
  validate.nonempty_text process.env.intershop_host_path
  validate.nonempty_text process.env.intershop_tmp_path
  addons              = []
  R                   = { addons, }
  R.populate_sql_path = PATH.join process.env.intershop_tmp_path, 'populate-addons-table.sql'
  R.host_path         = process.env.intershop_host_path
  package_json        = require PATH.join R.host_path, 'package.json'
  #.........................................................................................................
  for aoid of package_json.dependencies
    continue unless aoid.startsWith 'intershop-'
    #.......................................................................................................
    addon             = { aoid, path: ( resolve_pkg aoid ), }
    #.......................................................................................................
    unless addon.path?
      warn "^intershop/find-addons@478^ unable to locate #{aoid}; skipping"
      continue
    addon.relpath         = PATH.relative process.cwd(), addon.path
    #.......................................................................................................
    ### `ipj`: Intershop Package Json ###
    addon.ipj             = {}
    addon.ipj.path        = PATH.join addon.path, 'intershop-package.json'
    addon.ipj.relpath     = PATH.relative process.cwd(), addon.ipj.path
    #.......................................................................................................
    try ipj = require addon.ipj.path catch error
      throw error unless error.code is 'MODULE_NOT_FOUND'
      warn "^intershop/find-addons@478^ unable to locate #{addon.ipj.relpath}; skipping"
      continue
    #.......................................................................................................
    unless ( type = type_of ipj ) is 'object' then throw new Error \
      "^intershop/find-addons@478^ expected #{addon.ipj.relpath} to contain type object, found #{type}"
    #.......................................................................................................
    unless ( type = type_of ipj[ 'intershop-package-version' ] ) is 'text' then throw new Error \
      "^intershop/find-addons@478^ expected #{addon.ipj.relpath}#version to be a text, found #{type}"
    #.......................................................................................................
    unless ( version = ipj[ 'intershop-package-version' ] ) is '1.0.0' then throw new Error \
      "^intershop/find-addons@478^ expected InterShop Package version 1.0.0, found #{ipj.version} in #{addon.ipj.relpath}#version to be a text, found #{type}"
    #.......................................................................................................
    addon.ipj.version = ipj[ 'intershop-package-version' ]
    addon.files     = {}
    for file_id, target of ipj.files
      path                          = PATH.resolve PATH.join addon.path, file_id
      relpath                       = PATH.relative process.cwd(), path
      addon.files[ file_id ]        = { path, relpath, target, }
    #.......................................................................................................
    @validate_ipj_targets addon
    addons.push addon
  #.........................................................................................................
  return new_datom '^intershop-addons', R


############################################################################################################
if module is require.main then do =>
  addons = @find_addons()
  info '^10888^', addons
  for addon in addons.addons
    echo()
    echo  CND.white "Addon: #{addon.aoid}"
    echo  CND.grey  "  #{addon.path}"
    for file_id, file of addon.files
      { target, relpath, } = file
      color = switch target
        when 'app'      then CND.green
        when 'ignore'   then CND.grey
        when 'support'  then CND.gold
        when 'rebuild'  then CND.red
        else CND.grey
      target = ( ( target + ' ' ).padEnd 10, '—' ) + '>'
      echo "  #{color target} #{CND.lime relpath}"
    echo()
  # debug @find_addons()


