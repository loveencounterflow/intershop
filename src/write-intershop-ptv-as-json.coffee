
'use strict'

############################################################################################################
FS                        = require 'fs'
PATH                      = require 'path'
echo                      = console.log

{ settings, } = ( require './intershop' ).new_intershop()
keys          = ( Object.keys settings ).sort()
last_idx      = keys.length - 1
echo '{'
for idx in [ 0 .. last_idx ]
  key   = keys[ idx ]
  value = settings[ key ]
  comma = if idx is last_idx then '' else ','
  echo ( JSON.stringify key ) + ': ' + ( JSON.stringify value ) + comma
echo '}'

