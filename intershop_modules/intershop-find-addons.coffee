


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
package_json              = require PATH.resolve PATH.join process.env.intershop_host_path, 'package.json'
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
require 'cnd/lib/exception-handler'

#-----------------------------------------------------------------------------------------------------------
declare 'ishop_addon_target', ( x ) -> x in [ 'app', 'ignore', 'support', 'rebuild', ]

#-----------------------------------------------------------------------------------------------------------
@validate_ipj_targets = ( addon ) ->
  #.........................................................................................................
  unless ( type = type_of addon.ipj.targets ) is 'object' then throw new Error \
    "^intershop/find-addons@478^ expected #{addon.ipj.relpath}#targets to be an object, found #{type}"
  #.........................................................................................................
  if ( isa.empty Object.keys addon.ipj.targets ) then throw new Error \
    "^intershop/find-addons@478^ #{addon.ipj.relpath}#targets has no keys"
  #.........................................................................................................
  for path, { abspath, relpath, target, } of addon.ipj.targets
    if is_sad check.is_file abspath
      throw new Error """^intershop/find-addons@478^
      file #{rpr abspath}
      referred to in targets[ #{rpr path} ]
      of #{addon.ipj.relpath}
      does not exist"""
    unless isa.ishop_addon_target target then throw new Error \
      "^intershop/find-addons@478^ unknown target #{rpr target} in #{addon.ipj.relpath}#targets[ #{rpr path} ]"
  #.........................................................................................................
  return true

#-----------------------------------------------------------------------------------------------------------
@find_addons = ->
  R = {}
  for id of package_json.dependencies
    continue unless id.startsWith 'intershop-'
    #.......................................................................................................
    addon             = { id, }
    addon.module      = { path: ( resolve_pkg id ), }
    #.......................................................................................................
    unless addon.module.path?
      warn "^intershop/find-addons@478^ unable to locate #{id}; skipping"
      continue
    addon.module.relpath  = PATH.relative process.cwd(), addon.module.path
    #.......................................................................................................
    ### `ipj`: Intershop Package Json ###
    addon.ipj             = {}
    addon.ipj.path        = PATH.join addon.module.path, 'intershop-package.json'
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
    addon.ipj.targets = {}
    for path, target of ipj.targets
      abspath                       = PATH.resolve PATH.join addon.module.path, path
      relpath                       = PATH.relative process.cwd(), abspath
      addon.ipj.targets[ path ]     = { abspath, relpath, target, }
    #.......................................................................................................
    @validate_ipj_targets addon
    R[ addon.id ] = addon
  #.........................................................................................................
  return R


############################################################################################################
if module is require.main then do =>
  for addon_id, addon of @find_addons()
    urge    "Addon: #{addon_id}"
    whisper "  path: #{addon.module.path}"
    info    "  files:"
    for file_id, file of addon.ipj.targets
      { target, relpath, } = file
      color = switch target
        when 'app'      then CND.green
        when 'ignore'   then CND.grey
        when 'support'  then CND.gold
        when 'rebuild'  then CND.red
        else CND.grey
      target = ( ( target + ' ' ).padEnd 10, '—' ) + '>'
      help "    #{color target} #{CND.lime relpath}"

