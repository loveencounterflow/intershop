
require 'json/pure'

module PTV

  #---------------------------------------------------------------------------------------------------------
  def self.split_line( line )
    parts = ( line.strip ).split /\s+/, 3
    return {
      'path'  => parts[ 0 ],
      'type'  => parts[ 1 ],
      'value' => parts[ 2 ], }
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.hash_from_path( path )
    return self.update_hash_from_path path, {}
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.update_hash_from_path( path, r )
    File.foreach( path ).with_index do | line, linenr |
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      parts                 = split_line line
      r[ parts[ 'path' ] ]  = { 'type' => parts[ 'type' ], 'value' => parts[ 'value' ], }
      end
    return r
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.options_as_facet_json( x )
    return JSON.generate x
    end#def

  #---------------------------------------------------------------------------------------------------------
  def self.options_as_untyped_json( x )
    r = {}
    x.each do | key, facet |
      r[ key ] = facet[ 'value' ]
      end#do
    return JSON.generate r
    end#def


  #---------------------------------------------------------------------------------------------------------
  end#module
  #---------------------------------------------------------------------------------------------------------



