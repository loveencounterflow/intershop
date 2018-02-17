

'use strict'

defaults =
  app:
    name:    'intershop'
  db:
    port:    5433,
    name:    'intershop',
    user:    'intershop'
  rpc:
    port:    23001,
    host:    '127.0.0.1'
  respawn:
    # command:            [ 'node', 'app.js', ],
    command:            [ 'lib/intershop-rpc-server-secondary.js', ],
    name:               'intershop-rpc-server'        # set monitor name
    env:                { key: 'value', }             # set env vars
    cwd:                '.'                           # set cwd
    maxRestarts:        6                             # how many restarts are allowed within 60s or -1 for infinite restarts
    sleep:              100                           # time to sleep between restarts,
    kill:               30000                         # wait 30s before force killing after stopping
    # stdio:              [...]                         # forward stdio options
    fork:               true                          # fork instead of spawn

module.exports = ( require 'pkg-conf' ).sync 'intershop', { defaults, }




