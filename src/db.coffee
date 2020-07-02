

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/DB'
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
# ### TAINT due to the way that intershop determines the locations of `intershop.ptv` configuration files,
# we have to intermittently `cd` to the app directory: ###
# PATH                      = require 'path'
# prv_path                  = process.cwd()
# process.chdir PATH.join __dirname, '../..'
# whisper '33622', "working directory temporarily changed to #{process.cwd()}"
INTERSHOP                 = require '..'
O                         = INTERSHOP.settings
PTVR                      = INTERSHOP.PTV_READER
# process.chdir prv_path
# whisper '33622', "working directory changed to #{prv_path}"
#...........................................................................................................
db                        =
  ### TAINT value should be cast by PTV reader ###
  database:   O[ 'intershop/db/name' ].value
  port:       parseInt O[ 'intershop/db/port' ].value, 10
  user:       O[ 'intershop/db/user' ].value
#...........................................................................................................
pool_settings             =
  # database:                 'postgres',
  # user:                     'brianc',
  # password:                 'secret!',
  # port:                     5432,
  # ssl:                      true,
  # max:                      20, # set pool max size to 20
  idleTimeoutMillis:        1000, # close idle clients after 1 second
  connectionTimeoutMillis:  1000, # return an error after 1 second if connection could not be established
pool                      = new ( require 'pg' ).Pool db
Cursor                    = require 'pg-cursor'
SP                        = require 'steampipes'
{ $
  $async
  $watch
  $show
  $drain }                = SP.export()
#...........................................................................................................
assign                    = Object.assign
has_duplicates            = ( x ) -> ( new Set x ).size != x.length
last_of                   = ( x ) -> x[ x.length - 1 ]
keys_of                   = Object.keys
types                     = require './types'
{ isa
  type_of
  validate }              = types


#-----------------------------------------------------------------------------------------------------------
pluck = ( x, k ) -> R = x[ k ]; delete x[ k ]; return R

#-----------------------------------------------------------------------------------------------------------
@_get_query_object = ( q, settings... ) ->
  switch type = type_of q
    when 'pod'
      return assign {}, q, settings...
    when 'text'
      text    = q
      values  = null
    when 'list'
      [ text, values..., ] = q
    else throw new Error "expected a text or a list, got a #{type}"
  return assign { text, values, }, settings...

#-----------------------------------------------------------------------------------------------------------
@query = ( q, settings... ) ->
  ### TAINT since this method uses `pool.query`, transactions across more than a single call will fail.
  See https://node-postgres.com/features/transactions. ###
  #.........................................................................................................
  ### `result` is a single object with some added data or a list of such objects in the case of a multiple
  query; we reduce the latter to the last item: ###
  try
    result = await pool.query @_get_query_object q, settings...
  catch error
    warn "an exception occurred when trying to query #{rpr db} using"
    warn q
    throw error
  #.........................................................................................................
  ### acc. to https://node-postgres.com/features/connecting we have to wait here: ###
  # await pool.end()
  result = if isa.list result then ( last_of result ) else result
  #.........................................................................................................
  ### We return an empty list in case the query didn't return anything: ###
  return [] unless result?
  #.........................................................................................................
  ### We're only interested in the list of rows; again, if that list is empty, or it's a list of lists
  (when `rowMode: 'array'` was set), we're done: ###
  R = result.rows
  return [] if R.length is 0
  return R if isa.list R[ 0 ]
  #.........................................................................................................
  ### Otherwise, we've got a non-empty list of row objects. If the query specified non-unique field names,
  field names will clobber each other. To avoid silent failure, we check for duplicates and
  matching lengths of metadata and actual rows: ###
  keys = ( field.name for field in result.fields )
  #.........................................................................................................
  if ( has_duplicates keys ) or ( keys.length != ( keys_of R[ 0 ] ).length )
    error       = new Error "detected duplicate fieldnames: #{rpr keys}"
    error.code  = 'fieldcount mismatch'
    throw error
  #.........................................................................................................
  return ( { row..., } for row in R )

#-----------------------------------------------------------------------------------------------------------
@query_lists = ( q, settings... ) ->
  return await @query q, { rowMode: 'array', }, settings...

#-----------------------------------------------------------------------------------------------------------
@query_one = ( q, settings... ) ->
  rows = await @query q, settings...
  throw new Error "expected exactly one result row, got #{rows.length}" unless rows.length is 1
  return rows[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@query_one_list = ( q, settings... ) ->
  return await @query_one q, { rowMode: 'array', }, settings...

#-----------------------------------------------------------------------------------------------------------
@query_single = ( q, settings... ) ->
  R = await @query_one_list q, settings...
  throw new Error "expected row with single value, got on with #{rows.length} values" unless R.length is 1
  return R[ 0 ]

#-----------------------------------------------------------------------------------------------------------
@perform = ( q, settings... ) ->
  { text, values, } = @_get_query_object q
  lego  = ''
  lego += 'ð' while ( text.indexOf lego ) >= 0
  text += ';' unless text.endsWith ';'
  text  = "do $#{lego}$ begin perform #{text} end; $#{lego}$;"
  return await @query { text, values, }, settings...

#-----------------------------------------------------------------------------------------------------------
@new_query_source = ( q, settings... ) -> new Promise ( resolve, reject ) =>
  client_released = false
  client          = null
  cursor          = null
  source          = null
  #.........................................................................................................
  on_end = ->
    cursor.close =>
      source.end()
      client.release() unless client_released
      client_released = true
      resolve()
  #.........................................................................................................
  on_error = ( error ) =>
    ### NOTE obligatory error handling, absolutely must do this or app will hang, swallow errors: ###
    cursor.close =>
      client.release() unless client_released
      client_released = true
      await pool.end() unless pool.ended
      reject error
    return null
  #.........................................................................................................
  try
    client                      = await pool.connect()
    options                     = @_get_query_object q, settings...
    text                        = pluck options, 'text'
    values                      = pluck options, 'values'
    cursor                      = client.query new Cursor text, values, options
    source                      = SP.new_push_source()
    #.......................................................................................................
    read = -> new Promise ( resolve, reject ) =>
      cursor.read 100, ( error, rows ) =>
        if error?
          on_error error
          return reject()
        return on_end() if rows.length is 0
        resolve rows
    #.......................................................................................................
    source.start = -> do => ### Note: must be function, not asyncfunction ###
      loop
        rows = await read()
        source.send row for row in rows
      return null
    return resolve source
  #.........................................................................................................
  catch error
    throw error unless cursor?
    on_error error
  #.........................................................................................................
  return null



############################################################################################################
if require.main is module then do =>
  #.........................................................................................................
  try
    DB = @
    info '01', await DB.query        'select 42 as a, 108 as b;'
    info '02', await DB.query_one    'select 42 as a, 108 as b;'
    info '03', await DB.query_lists  'select 42 as a, 108 as b;'
    help '------------------------------------------------------------------------------------------'
    try
      info '04', await DB.query        'select 42, 108;'
    catch error
      throw error unless error.code is 'fieldcount mismatch'
      warn error.message
    help '------------------------------------------------------------------------------------------'
    info '05', await DB.query            'select 42, 108;', rowMode: 'array'
    info '06', await DB.query_lists      'select 42, 108;'
    info '07', await DB.query_one_list   'select 42, 108;'
    info '08', await DB.query_single     'select 42;'
    help '------------------------------------------------------------------------------------------'
    info '09', await DB.query            'select 42; select 108;'
    try
      info '10', await DB.query            'do $$ begin perform log( $a$helo$a$ ); end; $$;'
      info '11', await DB.perform          'log( $$helo$$ );'
      info '12', await DB.perform          'log( $ððð$helo$ððð$ );'
    catch error
      relpath = ( require 'path' ).relative process.cwd(), __filename
      warn '^2298^', "demos with SQL `log()` only work when run in intershop process, e.g."
      warn '^2298^', "  intershop node #{relpath}"
      warn "terminated with #{error.message}"
      process.exit 1
    #-----------------------------------------------------------------------------------------------------------
    demo_stream = ( q, settings... ) -> new Promise ( resolve, reject ) =>
      source      = await DB.new_query_source q, settings...
      pipeline    = []
      pipeline.push source
      pipeline.push SP.$show()
      pipeline.push $drain -> help 'ok'; resolve()
      SP.pull pipeline...
      # source.end()
      return null
    # demo_stream "select * from STROKEORDERS.strokeordersXXX limit x10"
    await demo_stream "select * from generate_series( 100, 110 ) as count;"
    await demo_stream "select * from generate_series( 100, 110 ) as count;", { rowMode: 'array', }
  #.........................................................................................................
  finally
    ### NOTE always call `pool.end()` to keep app from waiting for timeout: ###
    await pool.end() unless pool.ended
  #.........................................................................................................
  return null

@_db    = db
@_pool  = pool

