


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP/RPC/SECONDARY'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
FS                        = require 'fs'
PATH                      = require 'path'
NET                       = require 'net'
#...........................................................................................................
PS                        = require 'pipestreams'
{ $
  $async }                = PS
#...........................................................................................................
O                         = require './options'

# debug '84874', '⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖'
# for key, value of process.env
#   continue unless ( key.match /mojikura|intershop/ )?
#   debug key, value

#-----------------------------------------------------------------------------------------------------------
@_acquire_host_rpc_routines = ->
  intershop_host_modules_path = process.env[ 'intershop_host_modules_path' ]
  help '^3334^', "trying to acquire RPC routines from #{rpr intershop_host_modules_path}"
  if ( intershop_host_modules_path )?
    host_rpc_module_path  = PATH.join intershop_host_modules_path, 'rpc.js'
    host_rpc              = null
    ### Make sure to accept missing `rpc.js` module without swallowing errors occurring during import: ###
    try require.resolve host_rpc_module_path catch error
      throw error unless error.code is 'MODULE_NOT_FOUND'
      warn "no such module: #{rpr host_rpc_module_path}"
      return null
    host_rpc = require host_rpc_module_path
    for key, value of host_rpc
      info '33829', "add host RPC attribute #{rpr key}"
      @[ key ] = value
  return null

#-----------------------------------------------------------------------------------------------------------
@_socket_listen_on_all = ( socket ) ->
  socket.on 'close',      -> help 'socket', 'close'
  socket.on 'connect',    -> help 'socket', 'connect'
  socket.on 'data',       -> help 'socket', 'data'
  socket.on 'drain',      -> help 'socket', 'drain'
  socket.on 'end',        -> help 'socket', 'end'
  socket.on 'error',      -> help 'socket', 'error'
  socket.on 'lookup',     -> help 'socket', 'lookup'
  socket.on 'timeout',    -> help 'socket', 'timeout'
  return null

#-----------------------------------------------------------------------------------------------------------
@_server_listen_on_all = ( server ) ->
  server.on 'close',      -> help 'server', 'close'
  server.on 'connection', -> help 'server', 'connection'
  server.on 'error',      -> help 'server', 'error'
  server.on 'listening',  -> help 'server', 'listening'
  return null

#-----------------------------------------------------------------------------------------------------------
@listen = ( handler = null ) ->
  @_acquire_host_rpc_routines()
  #.........................................................................................................
  server = NET.createServer ( socket ) =>
    socket.on 'error', ( error ) => warn "socket error: #{error.message}"
    #.......................................................................................................
    source    = PS._nodejs_input_to_pull_source socket
    counts    = { requests: 0, rpcs: 0, hits: 0, fails: 0, errors: 0, }
    S         = { socket, counts, }
    pipeline  = []
    on_stop   = PS.new_event_collector 'stop', => socket.end()
    #.......................................................................................................
    pipeline.push source
    pipeline.push PS.$split()
    # pipeline.push PS.$show()
    pipeline.push @$show_counts   S
    pipeline.push @$dispatch      S
    pipeline.push on_stop.add PS.$drain()
    #.......................................................................................................
    PS.pull pipeline...
    return null
  #.........................................................................................................
  handler ?= =>
    { address: host, port, family, } = server.address()
    help "#{O.app.name} RPC server listening on #{family} #{host}:#{port}"
  #.........................................................................................................
  # ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
  # try FS.unlinkSync O.rpc.path catch error then warn error
  # server.listen O.rpc.path, handler
  # ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
  server.listen O.rpc.port, O.rpc.host, handler
  process.on 'uncaughtException',   -> warn "^8876^ uncaughtException";   server.close -> whisper "RPC server closed"
  process.on 'unhandledRejection',  -> warn "^8876^ unhandledRejection";  server.close -> whisper "RPC server closed"
  process.on 'exit',                -> warn "^8876^ exit";                server.close -> whisper "RPC server closed"
  return null

#-----------------------------------------------------------------------------------------------------------
@$show_counts = ( S ) ->
  return PS.$watch ( event ) ->
    S.counts.requests += +1
    if ( S.counts.requests % 1000 ) is 0
      urge JSON.stringify S.counts
    return null

#-----------------------------------------------------------------------------------------------------------
@$dispatch = ( S ) ->
  return $ ( line, send ) =>
    try
      event                   = JSON.parse line
      [ method, parameters, ] = event
    catch error
      method      = 'error'
      parameters  = "An error occurred while trying to parse #{rpr event}:\n#{error.message}"
    # debug '27211', ( rpr method ), ( rpr parameters )
    #.......................................................................................................
    switch method
      when 'error'    then @send_error S, parameters
      #.....................................................................................................
      ### Send `stop` signal to primary and exit secondary: ###
      when 'stop'
        process.send 'stop'
        process.exit()
      #.....................................................................................................
      ### exit and have primary restart secondary: ###
      when 'restart'
        process.exit()
      #.....................................................................................................
      else
        @do_rpc S, method, parameters
    #.......................................................................................................
    send event

#-----------------------------------------------------------------------------------------------------------
@do_rpc = ( S, method_name, parameters ) ->
  S.counts.rpcs  += +1
  method          = @[ "rpc_#{method_name}" ]
  return @send_error S, "no such method: #{rpr method_name}" unless method?
  #.........................................................................................................
  try
    result = method.call @, S, parameters
  catch error
    S.counts.errors += +1
    try
      { message, } = error
    catch error_2
      null
    message ?= '(UNKNOWN ERROR MESSAGE)'
    return @send_error S, error.message
  @_write S, method_name, result

#-----------------------------------------------------------------------------------------------------------
@send_error = ( S, message ) ->
  @_write S, 'error', message

#-----------------------------------------------------------------------------------------------------------
@_write = ( S, method, parameters ) ->
  S.socket.write ( JSON.stringify [ method, parameters, ] ) + '\n'
  return null


#===========================================================================================================
# RPC METHODS
#-----------------------------------------------------------------------------------------------------------
# { IDL, IDLX, }            = require 'mojikura-idl'

#-----------------------------------------------------------------------------------------------------------
@rpc_helo = ( S, P ) ->
  return "helo #{rpr P}"

#-----------------------------------------------------------------------------------------------------------
@rpc_add = ( S, P ) ->
  unless ( CND.isa_list P ) and ( P.length is 2 )
    throw new Error "expected a list with two numbers, got #{rpr P}"
  [ a, b, ] = P
  unless ( CND.isa_number a ) and ( CND.isa_number b )
    throw new Error "expected a list with two numbers, got #{rpr P}"
  return a + b

#-----------------------------------------------------------------------------------------------------------
@rpc_add_integers_only = ( S, P ) ->
  unless ( CND.isa_list P ) and ( P.length is 2 )
    throw new Error "expected a list with two numbers, got #{rpr P}"
  [ a, b, ] = P
  unless ( CND.isa_number a ) and ( CND.isa_number b )
    throw new Error "expected a list with two numbers, got #{rpr P}"
  unless ( a == Math.floor a )
    throw new Error "expected an integer, got #{rpr a}"
  unless ( b == Math.floor b )
    throw new Error "expected an integer, got #{rpr b}"
  return a + b

# #-----------------------------------------------------------------------------------------------------------
# @rpc_normalize_formula = ( S, P ) ->
#   unless ( CND.isa_list P ) and ( P.length is 2 )
#     throw new Error "expected a list with two texts, got #{rpr P}"
#   [ glyph, original_formula, ] = P
#   unless ( CND.isa_text glyph ) and ( CND.isa_text original_formula )
#     throw new Error "expected a list with two texts, got #{rpr P}"
#   #.........................................................................................................
#   normalized_formula  = IDLX.minimize_formula original_formula
#   if normalized_formula is original_formula then  S.counts.fails += +1
#   else                                            S.counts.hits  += +1
#   # debug '44432', rpr normalized_formula
#   # if normalized_formula? and normalized_formula isnt original_formula
#   #   debug '66672', glyph, original_formula, '->', normalized_formula if ( original_formula.match /∅/ )?
#   #   event.data.row.formula = MKNCR.chrs_from_text normalized_formula
#   return [ glyph, normalized_formula, ]

# #-----------------------------------------------------------------------------------------------------------
# @rpc_get_relational_bigrams = ( S, P ) ->
#   unless ( CND.isa_list P ) and ( P.length is 1 )
#     throw new Error "expected a list with one text, got #{rpr P}"
#   [ formula, ] = P
#   return null if formula is null
#   unless ( CND.isa_text formula )
#     throw new Error "expected a list with one text, got #{rpr P}"
#   #.........................................................................................................
#   return IDLX.get_relational_bigrams formula

# #-----------------------------------------------------------------------------------------------------------
# @rpc_get_relational_bigrams_as_indices = ( S, P ) ->
#   unless ( CND.isa_list P ) and ( P.length is 1 )
#     throw new Error "expected a list with one text, got #{rpr P}"
#   [ formula, ] = P
#   return null if formula is null
#   unless ( CND.isa_text formula )
#     throw new Error "expected a list with one text, got #{rpr P}"
#   #.........................................................................................................
#   return IDLX.get_relational_bigrams_as_indices formula

# #-----------------------------------------------------------------------------------------------------------
# @rpc_XCTO_demo = ( S, P ) ->
#   debug '33344', P
#   # unless ( CND.isa_list P ) and ( P.length is 1 )
#   #   throw new Error "expected a list with one text, got #{rpr P}"
#   # [ formula, ] = P
#   # return null if formula is null
#   # unless ( CND.isa_text formula )
#   #   throw new Error "expected a list with one text, got #{rpr P}"
#   #.........................................................................................................
#   return rpr P


# ############################################################################################################
# do ( L = @ ) ->
#   for name, method of L
#     continue unless name.startsWith 'rpc_'
#     L[ name ] = method.bind L


############################################################################################################
unless module.parent?
  RPCS = @
  RPCS.listen()


