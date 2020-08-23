


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'RESOLVE-NPM-DEPS'
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
# FS                        = require 'fs'
#...........................................................................................................
# types                     = require './types'
# { isa
#   validate
#   cast
#   check
#   declare
#   declare_check
#   is_sad
#   type_of }               = types.export()
get_tree                  = require 'npm-logical-tree'


#-----------------------------------------------------------------------------------------------------------
@get_package_dependencies = ( path )  ->
  ### Given a `path` to an npm  module that should contain a `package.json` and a `package-lock.json` file,
  return a report of transitive dependencies. The report will be an object with three fields:

  * **`packages`**—a list of pairs of package names and versions (`[ 'name', '1.1.0', ]`); these are in
    their installation order, i.e. each versioned package appears earlier than the packages that depend on
    it.

  * **`parents`**—an object whose keys are JSON representations os the values of `packages`, so like
    `'["opentype.js","1.3.3"]'`, and whose values are pairs of package names and versions as above.

  * **`duplicates`**—An object whose keys are unversioned package names and whose values are lists of
    versions in no particular order.

  ###
  pkg             = require PATH.join path, 'package.json'
  pkgLock         = require PATH.join path, 'package-lock.json'
  tree            = get_tree pkg, pkgLock
  { packages
    parents  }    = @_get_package_dependencies tree
  #.........................................................................................................
  # Assemble a string `parent@version, parent@version, ...` for each package:
  for key, value of parents
    value           = [ value..., ]
    value           = ( JSON.parse k for k in value )
    parents[ key ]  = value
  #.........................................................................................................
  # Keep only first appearance of each versioned package in dependency-sorted list:
  packages        = [ ( new Set packages )..., ]
  packages        = ( ( JSON.parse d ) for d in packages )
  #.........................................................................................................
  # Based on the packages list, find dependencies with more than a single version:
  duplicates      = {}
  for [ name, version, ] in packages
    ( duplicates[ name ] ?= new Set() ).add version
  for name, versions of duplicates
    if versions.size < 2
      delete duplicates[ name ]
      continue
    duplicates[ name ] = [ versions..., ]
  #.........................................................................................................
  return { packages, parents, duplicates, }

#-----------------------------------------------------------------------------------------------------------
@_get_package_dependencies = ( tree, R = null, seen = null, level = 0 )  ->
  seen       ?= new WeakSet()
  R          ?= { packages: [], parents: {}, }
  # dent        = '  '.repeat level ### verbose ###
  parent_key  = JSON.stringify [ tree.name, tree.version, ]
  seen.add tree
  if level > 0
    R.packages.unshift parent_key
    # urge "#{dent}#{parent_key}" ### verbose ###
  for [ name, sub_tree, ] from tree.dependencies.entries()
    sub_key = JSON.stringify [ sub_tree.name, sub_tree.version, ]
    target  = R.parents[ sub_key ] ?= new Set()
    target.add parent_key
    if seen.has sub_tree
      R.packages.unshift sub_key
      # whisper "#{dent}#{sub_key} (circular)" ### verbose ###
      continue
    @_get_package_dependencies sub_tree, R, seen, level + 1
  return R

#-----------------------------------------------------------------------------------------------------------
@get_intershop_addon_installation_order = ( path ) ->
  dependencies    = @get_package_dependencies path
  { packages
    parents
    duplicates }  = dependencies
  info packages
  urge parents
  info duplicates
  @_complain_about_duplicates dependencies
  return ( [ name, version, ] for [ name, version, ] in packages when /^intershop-/.test name )

#-----------------------------------------------------------------------------------------------------------
@_complain_about_duplicates = ( dependencies ) ->
  # Complain about duplicates (only one version of a given InterShop Addon can be installed as they all
  # write to the same DB):
  { packages
    parents
    duplicates }  = dependencies
  duplicate_names = []
  for package_name, versions of duplicates
    continue unless /^intershop-/.test package_name
    warn "multiple versions of package #{rpr package_name} detected:"
    duplicate_names.push package_name
    for version in versions
      key         = JSON.stringify [ package_name, version, ]
      required_by = parents[ key ] ? [ [ "UNKNOWN", "UNKNOWN", ], ]
      required_by = ( "#{p}@#{v}" for [ p, v, ] in required_by )
      required_by = required_by.join ', '
      warn "  version #{version} required_by by #{required_by}"
  if duplicate_names.length > 0
    throw new Error "duplicate versions for packages #{duplicate_names.join ', '} detected; see details above"
  return null


