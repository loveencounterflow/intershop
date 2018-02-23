
FS = require 'fs'

#-----------------------------------------------------------------------------------------------------------
@split_line = ( line ) ->
  [ path, type, value, ] = line.trim().split /\s+/, 3
  return { path, type, value, }

#-----------------------------------------------------------------------------------------------------------
@hash_from_path = ( path ) ->
  return @update_hash_from_path path, {}

#-----------------------------------------------------------------------------------------------------------
@update_hash_from_path = ( path, R ) ->
  source  = FS.readFileSync path, encoding: 'utf-8'
  for line in ( source.split '\n' )
    continue if ( line.match /^\s*$/ )?
    continue if ( line.match /^\s*#/ )?
    { path, type, value, }  = split_line line
    R[ parts.path ]         = { type, value, }
  return R

#-----------------------------------------------------------------------------------------------------------
@options_as_facet_json = ( x ) ->
  return JSON.stringify x

#-----------------------------------------------------------------------------------------------------------
@options_as_untyped_json = ( x ) ->
  R = {}
  R[ key ] = facet.value for key, facet of x
  return JSON.stringify R

