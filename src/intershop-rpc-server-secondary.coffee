

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'RCP-SERVER'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
NET                       = require 'net'
#...........................................................................................................
PS                        = require 'pipestreams'
{ $
  $async }                = PS
#...........................................................................................................
config                    = require 'config'
rpc_port                  = config.get 'rpc.port'
rpc_host                  = config.get 'rpc.host'


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
    pipeline.push @$parse_signal()
    # pipeline.push PS.$show()
    pipeline.push @$show_counts   S
    pipeline.push @$dispatch      S
    # pipeline.push PS.$show()
    pipeline.push on_stop.add PS.$drain()
    #.......................................................................................................
    PS.pull pipeline...
    return null
  #.........................................................................................................
  handler ?= =>
    { address: host, port, family, } = server.address()
    help "listening on #{family} #{host}:#{port}"
  #.........................................................................................................
  server.listen rpc_port, rpc_host, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@$show_counts = ( S ) ->
  return PS.$watch ( event ) ->
    S.counts.requests += +1
    if ( S.counts.requests % 1000 ) is 0
      urge JSON.stringify S.counts
    return null

#-----------------------------------------------------------------------------------------------------------
@$parse_signal = ( S ) ->
  return PS.map ( line ) =>
    try
      R = JSON.parse line
    catch error
      warn "#{error.message} (in #{rpr line})"
      R = line
    return R

#-----------------------------------------------------------------------------------------------------------
@$dispatch = ( S ) ->
  return $ ( event, send ) =>
    { channel, command, role, data, } = event
    switch command
      when 'helo' then help rpr data
      when 'data' then urge rpr data
      when 'rpc'  then @do_rpc S, channel, command, data
      else
        warn "unable to interpret #{rpr event}"
    send data

#-----------------------------------------------------------------------------------------------------------
@do_rpc = ( S, channel, command, data ) ->
  S.counts.rpcs                        += +1
  { method: method_name, parameters, }  = data
  method                                = @[ "rpc_#{method_name}" ]
  return @_write_a S, channel, 'error', "no such method: #{rpr method_name}" unless method?
  #.........................................................................................................
  try
    result = method.call @, S, parameters
  catch error
    debug '44938', error
    S.counts.errors += +1
    return @_write_a S, channel, 'error', error.message
  @_write_a S, channel, command, result

#-----------------------------------------------------------------------------------------------------------
@_write_a = ( S, channel, command, data ) ->
  line = ( JSON.stringify { channel, command, role: 'a', data, } )
  S.socket.write line + '\n'
  return null


#===========================================================================================================
# RPC METHODS
#-----------------------------------------------------------------------------------------------------------
# { IDL, IDLX, }            = require 'mojikura-idl'

#-----------------------------------------------------------------------------------------------------------
@rpc_add = ( S, P ) ->
  unless ( CND.isa_list P ) and ( P.length is 2 )
    throw new Error "expected a list with two numbers, got #{rpr P}"
  [ a, b, ] = P
  unless ( CND.isa_number a ) and ( CND.isa_number b )
    throw new Error "expected a list with two numbers, got #{rpr P}"
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


