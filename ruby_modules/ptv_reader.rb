
require 'json/pure'

#-----------------------------------------------------------------------------------------------------------
def split_ptv_line( line )
  parts = ( line.strip ).split /\s+/, 3
  return {
    'path'  => parts[ 0 ],
    'type'  => parts[ 1 ],
    'value' => parts[ 2 ], }
  end

#-----------------------------------------------------------------------------------------------------------
def ptv_hash_from_path( path )
  return update_ptv_hash_from_path path, {}
  end

#-----------------------------------------------------------------------------------------------------------
def update_ptv_hash_from_path( path, r )
  File.foreach( path ).with_index do | line, linenr |
    next if line =~ /^\s*$/
    next if line =~ /^\s*#/
    parts                 = split_ptv_line line
    r[ parts[ 'path' ] ]  = { 'type' => parts[ 'type' ], 'value' => parts[ 'value' ], }
    end
  return r
  end

#-----------------------------------------------------------------------------------------------------------
def options_as_facet_json( x )
  return JSON.generate x
  end

#-----------------------------------------------------------------------------------------------------------
def options_as_untyped_json( x )
  r = {}
  x.each do | key, facet |
    r[ key ] = facet[ 'value' ]
  end
  return JSON.generate r
  end






