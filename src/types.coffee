


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/TYPES'
debug                     = CND.get_logger 'debug',     badge
intertype                 = new ( require 'intertype' ).Intertype module.exports
# FS                        = require 'fs'

#-----------------------------------------------------------------------------------------------------------
@declare 'intershop_addon_location', tests:
  "x is a nonempty_text":                     ( x ) -> @isa.nonempty_text x
  "x must be 'guest' or 'host'":              ( x ) -> x in [ 'guest', 'host', ]

#-----------------------------------------------------------------------------------------------------------
@declare 'intershop_cli_psql_run_selector', tests:
  "x is a nonempty_text":                     ( x ) -> @isa.nonempty_text x
  "x must be '-c' or '-f'":                   ( x ) -> x in [ '-c', '-f', ]

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_clean_filename', tests:
#   ###
#   acc. to https://github.com/parshap/node-sanitize-filename:
#     Control characters (0x00–0x1f and 0x80–0x9f)
#     Reserved characters (/, ?, <, >, \, :, *, |, and ")
#     Unix reserved filenames (. and ..)
#     Trailing periods and spaces (for Windows)
#   ###
#   "x is a nonempty_text":                   ( x ) -> @isa.nonempty_text x
#   "x does not contain control chrs":        ( x ) -> not ( x.match /[\x00-\x1f]/      )?
#   "x does not contain meta chrs":           ( x ) -> not ( x.match /[\/?<>\:*|"]/     )?
#   "x is not `.` or `..`":                   ( x ) -> not ( x.match /^\.{1,2}$/        )?
#   "x has no whitespace":                    ( x ) -> not ( x.match /\s/               )?

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_existing_filesystem_object', tests:
#   "x is a nonempty_text":                   ( x ) -> @isa.nonempty_text x
#   "x points to existing fso":               ( x ) ->
#     try FS.statSync x catch error then return false
#     return true

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_existing_file', tests:
#   "x is a nonempty_text":                   ( x ) -> @isa.nonempty_text x
#   "x points to existing file":              ( x ) ->
#     try return ( FS.statSync x ).isFile() catch error then return false

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_existing_folder', tests:
#   "x is a nonempty_text":                   ( x ) -> @isa.nonempty_text x
#   "x points to existing folder":            ( x ) ->
#     try return ( FS.statSync x ).isDirectory() catch error then return false

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_settings',
#   tests:
#     "x is a object":                          ( x ) -> @isa.object              x
#     "x.source_path is a nonempty_text":       ( x ) -> @isa.nonempty_text       x.source_path
#     "x.target_path is a nonempty_text":       ( x ) -> @isa.nonempty_text       x.target_path

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_tagger_job_settings',
#   tests:
#     "x is a object":                          ( x ) -> @isa.object  x
#     "x.dry is a boolean":                     ( x ) -> @isa.boolean x.dry
#     "x.quiet is a boolean":                   ( x ) -> @isa.boolean x.quiet

# #-----------------------------------------------------------------------------------------------------------
# @declare 'fontmirror_fontfile_extensions', ( x ) ->
#     return false unless @isa.list x
#     return x.every ( e ) => @isa.nonempty_text e

# #-----------------------------------------------------------------------------------------------------------
# ### TAINT experimental ###
# L = @
# @cast =

#   #---------------------------------------------------------------------------------------------------------
#   iterator: ( x ) ->
#     switch ( type = L.type_of x )
#       when 'generator'          then return x
#       when 'generatorfunction'  then return x()
#       when 'list'               then return ( -> y for y in x )()
#     throw new Error "^fontmirror/types@3422 unable to cast a #{type} as iterator"

#   #---------------------------------------------------------------------------------------------------------
#   hex: ( x ) ->
#     L.validate.nonnegative_integer x
#     return '0x' + x.toString 16


# #-----------------------------------------------------------------------------------------------------------
# @defaults =
#   fontmirror_cli_command_settings:
#     dry:          false
#     quiet:        false






