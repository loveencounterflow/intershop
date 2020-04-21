

'use strict'



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'REFRESH-MIRAGE-DATASOURCES'
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
#...........................................................................................................
parallel                  = require './parallel-promise'
DB                        = require './db'
#...........................................................................................................
INTERSHOP                 = require '..'
O                         = INTERSHOP.settings
PTVR                      = INTERSHOP.PTV_READER

# for path, { type, value } of O
#   info ( path.padEnd 45 ), ( CND.grey type.padEnd 15 ), ( CND.white value )

### TAINT PTV reader should cast values ###
### TAINT need API (proxy?) so we get error for non-existant names ###
dsk_parallel_limit        = parseInt O[ 'intershop/mirage/parallel-limit' ].value, 10
debug '^3344^', 'dsk_parallel_limit:', dsk_parallel_limit


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@get_dsk_definitions = ->
  R = {}
  #.........................................................................................................
  for [ settings_path, { type, value, }, ] in PTVR.match O, 'intershop/mirage/dsk/**'
    dsk = settings_path.replace /^intershop\/mirage\/dsk\//g, ''
    #.......................................................................................................
    unless type is 'url'
      throw new Error "expected type 'url', got type #{rpr type}"
    #.......................................................................................................
    unless ( match = value.match /^([^:]+):(.*$)/ )?
      throw new Error "expected value like 'mode:/path/to/source...', got #{rpr value}"
    [ _, mode, path, ] = match
    #.......................................................................................................
    if ( match = dsk.match /-([0-9]+)$/ )?
      [ _, idx, ] = match
      idx         = ( parseInt idx, 10 ) - 1
      dsk         = dsk[ ... match.index ]
      ( R[ dsk ]?= [] )[ idx ] = { mode, path, }
    #.......................................................................................................
    else
      ( R[ dsk ]?= [] ).push { path, mode, }
  #.........................................................................................................
  # delete R[ 'formulas'                  ] # 2754912
  # delete R[ 'strokeorders'              ] # 3103259
  # delete R[ 'meanings'                  ] # 1398839
  # delete R[ 'sims'                      ] # 807439
  # delete R[ 'other/sawndip'             ] # 204981
  # delete R[ 'factor-hierarchy'          ] # 105592
  # delete R[ 'variantusage'              ] # 98000
  # delete R[ 'figural-themes'            ] # 70162
  # delete R[ 'other/zdic-factors'        ] # 22902
  # delete R[ 'other/kangxi-radicals'     ] # 19906
  # delete R[ 'other/guoxuedashi-factors' ] # 16894
  # delete R[ 'other/kanshudo-components' ] # 4839
  # delete R[ 'other/shuowen-radicals'    ] # 4256
  # delete R[ 'guides-similarity'         ] # 1311
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@_walk_dsk_pathmodes = ( dsk_definitions ) ->
  for dsk, pathmodes of dsk_definitions
    for { path, mode, } in pathmodes
      yield { dsk, path, mode, }

#-----------------------------------------------------------------------------------------------------------
@procure_mirage_datasources = ( dsk_definitions ) ->
  tasks = []
  for { dsk, path, mode, } from @_walk_dsk_pathmodes dsk_definitions
    do ( dsk, path, mode ) -> tasks.push ->
      q = [ 'select MIRAGE.procure_dsk_pathmode( $1, $2, $3 )', dsk, path, mode, ]
      whisper "^447^ procuring DSK #{rpr dsk}"
      await DB.query_single q
  await parallel tasks, 1

#-----------------------------------------------------------------------------------------------------------
@clear_mirage_cache = -> await DB.query 'select MIRAGE.clear_cache()'

#-----------------------------------------------------------------------------------------------------------
@vacuum_mirage_cache = -> await DB.query 'vacuum analyze MIRAGE.cache'

#-----------------------------------------------------------------------------------------------------------
@refresh_dsks = ( dsk_definitions, parallel_limit = 1 ) ->
  tasks           = []
  waiting_count   = 0
  running_count   = 0
  finished_count  = 0
  task_count      = 0
  for { dsk, path, mode, } from @_walk_dsk_pathmodes dsk_definitions
    do ( dsk, path, mode ) -> tasks.push ->
      waiting_count  += -1
      running_count  += +1
      # whisper "(w: #{waiting_count}, r: #{running_count}, f: #{finished_count} / #{t_count}) refreshing (#{mode}) #{path}"
      result          = await DB.query_single [ 'select MIRAGE.refresh( $1, $2 )', path, mode, ]
      running_count  += -1
      finished_count += +1
      # help    "(w: #{waiting_count}, r: #{running_count}, f: #{finished_count} / #{t_count}) refreshed (#{mode}) #{path}"
  waiting_count   = tasks.length
  t_count         = tasks.length
  await parallel tasks, parallel_limit
  return null

#-----------------------------------------------------------------------------------------------------------
@_show_dsk_definitions = ( dsk_definitions ) ->
  cwd = process.cwd()
  echo CND.steel CND.reverse CND.bold " Mirage Data Sources "
  echo CND.grey "DSK                                 DSNR  path"
  echo CND.grey "——————————————————————————————————— ————— —————————————————————————————————————"
  for dsk, modepaths of dsk_definitions
    dsk_txt       = ( CND.white dsk ).padEnd 50
    for { mode, path, }, idx in modepaths
      path          = ( PATH.relative cwd, path ) if path.startsWith cwd
      modepath_txt  = ( CND.yellow mode ) + ( CND.grey ':' ) + ( CND.lime path )
      nr_txt        = ( "#{idx + 1}".padStart 2 ) + '    '
      echo dsk_txt, nr_txt, modepath_txt
  return null


############################################################################################################
unless module.parent?
  RMDSKS = @
  do ->
    dsk_definitions = RMDSKS.get_dsk_definitions()
    RMDSKS._show_dsk_definitions dsk_definitions
    await RMDSKS.procure_mirage_datasources dsk_definitions
    # await RMDSKS.clear_mirage_cache()
    await RMDSKS.refresh_dsks dsk_definitions, dsk_parallel_limit
    await RMDSKS.vacuum_mirage_cache()
    process.exit 0


#  1 node lib/experiments/refresh-mirage-datasources.js  0.41s user 0.06s system 0% cpu 1:00.76 total
#  2 node lib/experiments/refresh-mirage-datasources.js  0.41s user 0.06s system 1% cpu 32.242 total
#  3 node lib/experiments/refresh-mirage-datasources.js  0.42s user 0.05s system 1% cpu 25.222 total
#  4 node lib/experiments/refresh-mirage-datasources.js  0.44s user 0.03s system 1% cpu 24.629 total
#  5 node lib/experiments/refresh-mirage-datasources.js  0.43s user 0.05s system 1% cpu 24.931 total
# 15 node lib/experiments/refresh-mirage-datasources.js  0.45s user 0.04s system 1% cpu 25.691 total


