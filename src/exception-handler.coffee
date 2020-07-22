

'use strict'


############################################################################################################
############################################################################################################
############################################################################################################
### see https://medium.com/@nodejs/source-maps-in-node-js-482872b56116
############################################################################################################
############################################################################################################
############################################################################################################


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'nodexh'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
stackman                  = ( require 'stackman' )()
FS                        = require 'fs'
PATH                      = require 'path'
{ red
  green
  steel
  grey
  cyan
  bold
  gold
  reverse
  white
  yellow
  reverse
  underline
  bold }                  = CND
# types                     = new ( require '../../intertype' ).Intertype()
# { isa }                   = types.export()

#-----------------------------------------------------------------------------------------------------------
alertxxx = ( P... ) -> process.stdout.write ' ' + CND.pen P...

#-----------------------------------------------------------------------------------------------------------
get_context = ( path, linenr, colnr ) ->
  ### TAINT use stackman.sourceContexts() instead ###
  try
    lines     = ( FS.readFileSync path, { encoding: 'utf-8' } ).split '\n'
    delta     = 1
    coldelta  = 5
    effect    = underline
    effect    = bold
    effect    = reverse
    first_idx = Math.max 0, linenr - 1 - delta
    last_idx  = Math.min lines.length - 1, linenr - 1 + delta
    R         = []
    for line, idx in lines[ first_idx .. last_idx ]
      this_linenr = first_idx + idx + 1
      lnr = ( this_linenr.toString().padStart 4 ) + '│ '
      if this_linenr is linenr
        c0  = colnr - 1
        c1  = colnr + coldelta
        line = line[ ... c0 ] + ( effect line[ c0 ... c1 ] ) + line[ c1 .. ]
        R.push  "#{grey lnr}#{cyan line}"
      else
        R.push  "#{grey lnr}#{grey line}"
    # R = R.join '\n'
  catch error
    throw error unless error.code is 'ENOENT'
    # return [ ( red "!!! #{rpr error.message} !!!" ), ]
    return []
  return R

#-----------------------------------------------------------------------------------------------------------
resolve_locations = ( frames, handler ) ->
  load_source_map = require 'load-source-map'
  debug '^3334^', ( k for k of load_source_map )
  for frame in frames
    path  = frame.file
    path  = null if path in [ '', undefined, ]
    continue unless path?
    do ( path ) ->
      load_source_map path, ( lsm_error, sourcemap ) ->
        return if lsm_error?
        return unless sourcemap?
        # return handler error if error?
        # return handler() unless sourcemap?
        position  = sourcemap.originalPositionFor { line: linenr, column: colnr, }
        linenr    = position.line
        colnr     = position.column
        # debug '^3387^', ( k for k of sourcemap )
        whisper 'load-source-map', position
        whisper 'load-source-map', { path, linenr, colnr, }
  handler()
  return null

#-----------------------------------------------------------------------------------------------------------
show_error_with_source_context = ( error, headline ) ->
  arrowhead   = white '▲'
  arrowshaft  = white '│'
  width       = process.stdout.columns
  # demo_error_stack_parser error
  # debug CND.cyan error.stack
  ##########################################################################################################
  stackman.callsites error, ( stackman_error, callsites ) ->
    debug '^2223^'
    throw stackman_error if stackman_error?
    callsites.reverse()
    callsites.forEach ( callsite ) ->
      unless ( path = callsite.getFileName() )?
        alertxxx grey '—'.repeat 108
        return null
      linenr    = callsite.getLineNumber()
      colnr     = callsite.getColumnNumber()
      relpath     = PATH.relative process.cwd(), path
      # debug "^8887^ #{rpr {path, linenr, callsite:callsite.getFileName(),sourceContexts:null}}"
      if path.startsWith 'internal/'
        alertxxx arrowhead, grey "#{relpath} ##{linenr}"
        return null
      # alertxxx()
      # alertxxx steel bold reverse ( "#{relpath} ##{linenr}:" ).padEnd 108
      alertxxx arrowhead, gold ( "#{relpath} ##{linenr}: \x1b[38;05;234m".padEnd width, '—' )
      source      = get_context path, linenr, colnr
      alertxxx arrowshaft, line for line in source
      return null
      alert reverse bold headline
    # if error?.message?
    return null
  return null

#-----------------------------------------------------------------------------------------------------------
@exit_handler = ( exception ) ->
  print               = alert
  message             = ' EXCEPTION: ' + ( exception?.message ? "an unrecoverable condition occurred" )
  if stack = exception?.where ? exception?.stack ? null
    message += '\n--------------------\n' + stack + '\n--------------------'
  [ head, tail..., ]  = message.split '\n'
  # debug '^222766^', { stack, }
  # debug '^222766^', { message, tail, }
  print reverse ' ' + head + ' '
  warn line for line in tail
  if exception?.stack?
    debug '^4445^', "show_error_with_source_context"
    show_error_with_source_context exception, ' ' + head + ' '
  else
    whisper exception?.stack ? "(exception undefined, no stack)"
  process.exitCode = 1
  # process.exit 111
@exit_handler = @exit_handler.bind @


############################################################################################################
unless global[ Symbol.for 'cnd-exception-handler' ]?
  global[ Symbol.for 'cnd-exception-handler' ] = true
  if process.type is 'renderer'
    window.addEventListener 'error', ( event ) =>
      # event.preventDefault()
      message = ( event.error?.message ? "(error without message)" ) + '\n' + ( event.error?.stack ? '' )[ ... 500 ]
      OPS.log message
      # @exit_handler event.error
      OPS.open_devtools()
      return true

    window.addEventListener 'unhandledrejection', ( event ) =>
      # event.preventDefault()
      message = ( event.reason?.message ? "(error without message)" ) + '\n' + ( event.reason?.stack ? '' )[ ... 500 ]
      OPS.log message
      # @exit_handler event.reason
      OPS.open_devtools()
      return true
  else
    process.on 'uncaughtException',  @exit_handler
    process.on 'unhandledRejection', @exit_handler

