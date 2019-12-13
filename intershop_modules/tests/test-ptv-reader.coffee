

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PTVR/TESTS'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
TAP                       = require 'tap'
eq                        = CND.equals
jr                        = JSON.stringify
PTVR                      = require '../ptv-reader'

#-----------------------------------------------------------------------------------------------------------
TAP.test "demo", ( T ) ->
  info PTVR.split_line 'foo/bar     ::integer[]= [ 1, 2, 3, 4, ]'
  info PTVR.split_line 'foo/bar     ::integer[]=  '
  info PTVR.split_line 'foo/bar     ::integer[]='
  #.........................................................................................................
  T.end()

#-----------------------------------------------------------------------------------------------------------
TAP.test "line splitting", ( T ) ->
  probes_and_matchers = [
    [ 'foo/bar     ::integer[]= [ 1, 2, 3, 4, ]', {path:'foo/bar',"type":"integer[]", value:'[ 1, 2, 3, 4, ]'} ]
    [ 'foo/bar     ::integer[]=  ', {path:'foo/bar',"type":"integer[]", value:''} ]
    [ 'foo/bar     ::integer[]=', {path:'foo/bar',"type":"integer[]", value:''} ]
    ]
  #.........................................................................................................
  for [ probe, matcher, ] in probes_and_matchers
    result = PTVR.split_line probe
    help jr [ probe, result, ]
    T.ok eq result, matcher
  #.........................................................................................................
  T.end()

#-----------------------------------------------------------------------------------------------------------
TAP.test "matching", ( T ) ->
  probe = {
    'intershop/path':              { type: 'text/path/folder', value: '/path/to/foobar',            },
    'intershop/rack/path':         { type: 'text/path/folder', value: '/path/to/foobar/..',         },
    'intershop/jzrds':             { type: 'text',             value: 'whtever1',   },
    'foo/bar/jzrds':               { type: 'text',             value: 'whtever2',   },
    'foo/bar/jzrds/something':     { type: 'text',             value: 'whtever3',   },
    'intershop/jzrds/path':        { type: 'text/path/folder', value: '/path/to/foobar/../jzrds',   },
    'intershop/testdata/path':     { type: 'text/path/folder', value: '/path/to/foobar/test-data',  }, }
  #.........................................................................................................
  for pattern in [ '**', '*/path', '**/path', '**/jzrds', '**/jzrds/**', ]
    urge pattern
    for [ path, { type, value, }, ] in PTVR.match probe, pattern
      info ( path.padEnd 45 ), ( CND.grey type.padEnd 15 ), ( CND.white value )
  #.........................................................................................................
  T.end()








