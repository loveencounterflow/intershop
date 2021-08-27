


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
SP                        = require 'steampipes'
{ $
  $async
  $watch
  $drain }                = SP.export()
#...........................................................................................................
DATOM                     = require 'datom'
{ new_datom
  select }                = DATOM.export()
#...........................................................................................................
@types                    = require './types'
{ isa
  validate
  cast
  type_of }               = @types
#...........................................................................................................
O                         = require './options'
process_is_managed        = module is require.main
{ jr }                    = CND



# debug '84874', '⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖⬖'
# for key, value of process.env
#   continue unless ( key.match /mojikura|intershop/ )?
#   debug key, value

#-----------------------------------------------------------------------------------------------------------
@_acquire_host_rpc_routines = ->
  ### TAINT test for name collisions ###
  ### TAINT do not require `rpc_` prefix? ###
  ### TAINT use dedicated namespace (object) to keep RPC methods ###
  ### TAINT make compatible with xemitter conventions ###
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
      info '^3389^', "add host RPC attribute #{rpr key}"
      @[ key ] = value
  return null

#-----------------------------------------------------------------------------------------------------------
@contract = ( key, method ) ->
  ### TAINT use dedicated namespace (object) to keep RPC methods ###
  ### TAINT make compatible with xemitter conventions ###
  validate.nonempty_text key
  validate.callable method
  rpc_key = "rpc_#{key}"
  if @[ rpc_key ]?
    throw new Error "^rpc-secondary/contract@55777^ method already exists: #{rpr key} (#{rpr rpc_key})"
  @[ rpc_key ] = method
  return null

#-----------------------------------------------------------------------------------------------------------
@_socket_listen_on_all = ( socket ) ->
  socket.on 'close',      -> whisper '^rpc-4432-1^', 'socket', 'close'
  socket.on 'connect',    -> whisper '^rpc-4432-2^', 'socket', 'connect'
  socket.on 'data',       -> whisper '^rpc-4432-3^', 'socket', 'data'
  socket.on 'drain',      -> whisper '^rpc-4432-4^', 'socket', 'drain'
  socket.on 'end',        -> whisper '^rpc-4432-5^', 'socket', 'end'
  socket.on 'error',      -> whisper '^rpc-4432-6^', 'socket', 'error'
  socket.on 'lookup',     -> whisper '^rpc-4432-7^', 'socket', 'lookup'
  socket.on 'timeout',    -> whisper '^rpc-4432-8^', 'socket', 'timeout'
  return null

#-----------------------------------------------------------------------------------------------------------
@_server_listen_on_all = ( server ) ->
  server.on 'close',      -> whisper '^rpc-4432-9^', 'server', 'close'
  server.on 'connection', -> whisper '^rpc-4432-10^', 'server', 'connection'
  server.on 'error',      -> whisper '^rpc-4432-11^', 'server', 'error'
  server.on 'listening',  -> whisper '^rpc-4432-12^', 'server', 'listening'
  return null

#-----------------------------------------------------------------------------------------------------------
@listen = ( handler = null ) ->
  @_acquire_host_rpc_routines()
  #.........................................................................................................
  server = NET.createServer ( socket ) =>
    #.......................................................................................................
    # @_socket_listen_on_all socket
    source    = SP.new_push_source()
    socket.on 'data',   ( data  ) => source.send data unless data is ''
    socket.on 'error',  ( error ) => warn "socket error: #{error.message}"
    # socket.on 'error',  ( error ) => throw error
    # socket.on 'end',              => source.end()
    counts    = { requests: 0, rpcs: 0, hits: 0, fails: 0, errors: 0, }
    S         = { socket, counts, }
    pipeline  = []
    #.......................................................................................................
    pipeline.push source
    pipeline.push SP.$split()
    # pipeline.push $watch ( d ) => urge '^3398^', jr d
    pipeline.push @$show_counts   S
    pipeline.push @$dispatch      S
    pipeline.push $drain()
    #.......................................................................................................
    SP.pull pipeline...
    return null
  #.........................................................................................................
  handler ?= =>
    { address: host, port, family, } = server.address()
    app_name = O.app.name ? process.env[ 'intershop_db_name' ] ? 'intershop'
    help "RPC server for #{app_name} listening on #{family} #{host}:#{port}"
  #.........................................................................................................
  # ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
  # try FS.unlinkSync O.rpc.path catch error then warn error
  # server.listen O.rpc.path, handler
  # ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
  # @_server_listen_on_all server
  server.listen O.rpc.port, O.rpc.host, handler
  @stop = -> server.close()
  # debug '^899555^', ( k for k of server)
  # process.on 'uncaughtException',   -> warn "^8876^ uncaughtException";   server.close -> whisper "RPC server closed"
  # process.on 'unhandledRejection',  -> warn "^8876^ unhandledRejection";  server.close -> whisper "RPC server closed"
  # process.on 'exit',                -> warn "^8876^ exit";                server.close -> whisper "RPC server closed"
  return null

#-----------------------------------------------------------------------------------------------------------
@$show_counts = ( S ) ->
  return $watch ( event ) ->
    S.counts.requests += +1
    if ( S.counts.requests % 1000 ) is 0
      urge JSON.stringify S.counts
    return null

#-----------------------------------------------------------------------------------------------------------
@$dispatch = ( S ) ->
  return $ ( line, send ) =>
    return null if line is ''
    event       = null
    method      = null
    parameters  = null
    $rsvp       = false
    #.......................................................................................................
    loop
      try event = JSON.parse line catch error
        @send_error S, """^rpc-secondary/$dispatch@5564^
          An error occurred while trying to parse #{rpr line}:
          #{error.message}"""
        break
      #.....................................................................................................
      switch type = type_of event
        # when 'list'
        #   warn "^rpc-secondary/$dispatch@5564^ using list instead of object in RPC calls is deprecated"
        #   [ method, parameters, ] = event
        #   $rsvp                   = true
        when 'object'
          { $key: method, $value: parameters, $rsvp, }  = event
          $rsvp                                        ?= false
        else
          @send_error S, "^rpc-secondary/$dispatch@5565^ expected object, got a #{type}: #{rpr event}"
          break
      #.....................................................................................................
      switch method
        when 'error'
          @send_error S, parameters
        #...................................................................................................
        ### Send `stop` signal to primary and exit secondary: ###
        when 'stop'
          process.send 'stop' if process_is_managed
          process.exit()
        #...................................................................................................
        ### exit and have primary restart secondary: ###
        when 'restart'
          unless process_is_managed
            warn "received restart signal but standalone process can't restart"
          else
            process.exit()
        #...................................................................................................
        else
          if $rsvp is true
            @do_rpc S, method, parameters
      #.....................................................................................................
      break
    #.......................................................................................................
    ### TAINT sending on failed lines w/out marking them as such? ###
    send event ? line
    return null

#-----------------------------------------------------------------------------------------------------------
@do_rpc = ( S, method_name, parameters ) ->
  S.counts.rpcs  += +1
  method          = @[ "rpc_#{method_name}" ]
  method_type     = type_of method
  return @send_error S, "no such method: #{rpr method_name}" unless method?
  #.........................................................................................................
  try
    switch method_type
      when 'function'       then  result =        method.call @, S, parameters
      when 'asyncfunction'  then  result = await  method.call @, S, parameters
      else throw new Error "unknown method type #{rpr method_type}"
  catch error
    S.counts.errors += +1
    try
      { message, } = error
    catch error_2
      null
    message ?= '(UNKNOWN ERROR MESSAGE)'
    return @send_error S, error.message
  if isa.promise result
    result.then ( result ) => @_write S, method_name, result
  else
    @_write S, method_name, result
  return null

#-----------------------------------------------------------------------------------------------------------
@send_error = ( S, message ) ->
  @_write S, 'error', message

#-----------------------------------------------------------------------------------------------------------
@_write = ( S, $method, parameters ) ->
  # debug '^intershop-rpc-server-secondary.coffee@3332^', ( rpr method_name ), ( rpr parameters )
  # if isa.object parameters  then  d = new_datom '^rpc-result', { $method, parameters..., }
  # else                            d = new_datom '^rpc-result', { $method, $value: parameters, }
  d = new_datom '^rpc-result', { $method, $value: parameters, }
  S.socket.write ( JSON.stringify d ) + '\n'
  return null


#===========================================================================================================
# RPC METHODS
#-----------------------------------------------------------------------------------------------------------
@rpc_has_rpc_method = ( S, P ) ->
  ### TAINT don't do ad-hoc name mangling, use dedicated namespace ###
  validate.nonempty_text P
  return @[ "rpc_#{P}" ]?

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


############################################################################################################
if module is require.main then do =>
  RPCS = @
  RPCS.listen()


# curl --silent --show-error localhost:23001/
# curl --silent --show-error localhost:23001
# curl --show-error localhost:23001
# grep -r --color=always -P '23001' db src bin tex-inputs | sort | less -SRN
# grep -r --color=always -P '23001' . | sort | less -SRN
# grep -r --color=always -P '23001|8910|rpc' . | sort | less -SRN


