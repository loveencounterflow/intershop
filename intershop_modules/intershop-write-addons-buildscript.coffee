


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


############################################################################################################
if module is require.main then do =>
  addons = ( require './intershop-find-addons' ).find_addons()
  for addon_id, addon of addons
    echo()
    echo "# #{'-'.repeat 108}"
    echo "# Addon: #{addon_id}"
    echo "# #{addon.module.path}"
    for file_id, file of addon.ipj.targets
      { target, relpath, abspath, } = file
      switch target
        when 'support'
          echo "# skipping support file #{abspath}"
        when 'rebuild'
          ### TAINT must escape critical characters ###
          echo "echo -e $orange$reverse $reset$orange'#{abspath}'$reset"
          echo "postgres_unpaged -f #{abspath}"
        else
          echo "# skipping #{abspath}"
  echo "# #{'-'.repeat 108}"
  echo "# (end of addons)"


