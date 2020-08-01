

/*

                             d8b          d8b 888
                             Y8P          Y8P 888
                                              888
88888b.  888  888            888 88888b.  888 888888
888 "88b 888  888            888 888 "88b 888 888
888  888 888  888            888 888  888 888 888
888 d88P Y88b 888            888 888  888 888 Y88b.
88888P"   "Y88888  88888888  888 888  888 888  "Y888
888           888
888      Y8b d88P
888       "Y88P"

*/


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U.py_init() returns void language plpython3u as $$
# plpy.notice( '^22234-1^', "U.py_init() called")
if 'ctx' in GD: return
plpy.notice( '^22234-2^', "U.py_init() no ctx in GD")

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
import sys
import os
import re
from pathlib import Path
#...........................................................................................................
# https://stackoverflow.com/a/29548234
# https://stackoverflow.com/a/29548234/7568091
class AttributeDict(dict):
  def __getattr__(self, attr):
    return self[attr]
  def __setattr__(self, attr, value):
    self[attr] = value
#...........................................................................................................
ctx               = AttributeDict()
target            = AttributeDict()
GD[ 'ctx' ]       = ctx
ctx.plpy          = plpy
ctx.addons        = AttributeDict()
ctx.execute       = plpy.execute
ctx.notice        = plpy.notice
ctx.AttributeDict = AttributeDict

#-----------------------------------------------------------------------------------------------------------
def get_variable( key ):
  sql   = """select ¶( $1 ) as value"""
  plan  = plpy.prepare( sql, [ 'text', ] )
  rows  = plpy.execute( plan, [ key, ] )
  if len( rows ) != 1:
    raise Exception( "unable to find setting " + repr( key ) + " in U.variables" )
  return rows[ 0 ][ 'value' ]
#...........................................................................................................
def get_variable_names():
  sql   = """select key from U.variables order by key"""
  plan  = plpy.prepare( sql )
  rows  = plpy.execute( plan )
  return list( row[ 'key' ] for row in rows )
#...........................................................................................................
def set_variable( key, value ):
  sql   = """select ¶( $1, $2 )"""
  plan  = plpy.prepare( sql, [ 'void', ] )
  rows  = plpy.execute( plan, [ key, value, ] )
#...........................................................................................................
ctx.get_variable        = get_variable
ctx.get_variable_names  = get_variable_names
ctx.set_variable        = set_variable

#-----------------------------------------------------------------------------------------------------------
def _absorb_environment( ctx ):
  sql   = """
    select regexp_replace( key, '/', '_', 'g' ) as key, value
      from U.variables where key ~ '^intershop/';"""
  plan  = plpy.prepare( sql )
  rows  = plpy.execute( plan )
  for row in rows:
    ctx[ row[ 'key' ] ] = row[ 'value' ]
  # ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
  # ### TAINT for the moment we manually cast some values:
  # ctx.intershop_rpc_port = int( ctx.intershop_rpc_port )
  # ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
#...........................................................................................................
### TAINT some variables will have wrong type (stringly typed enviroment variables) ###
_absorb_environment( ctx )

#===========================================================================================================
# STDOUT REDIRECTION
#-----------------------------------------------------------------------------------------------------------
# Capture output to plPython3''s `sys.stdout` and make
# it produce calls to `plpy.notice()`; also, when `ctx.log()` has not yet been defined, make calls to
# `ctx.log()` also produce calls to `plpy.notice()`. This way, calls to `print()` and `ctx.log() in
# plPython3 functions will not cause errors and produce visible output from an early point in time
# onwards.
class Redirector:

  #---------------------------------------------------------------------------------------------------------
  def __init__( me ):
    me.buffer = []

  #---------------------------------------------------------------------------------------------------------
  def pen( me, *P ):
    R = ''
    for p in P:
      if not isinstance( p, str ): p = str( p )
      R += p
    return R

  #---------------------------------------------------------------------------------------------------------
  def write( me, message ): me._write( me.pen( message ) )

  #---------------------------------------------------------------------------------------------------------
  def _write( me, text ):
    for part in re.split( '(\n)', text ):
      if part == '\n':
        plpy.notice( ''.join( me.buffer ) )
        me.buffer.clear()
      else:
        me.buffer.append( part )

#-----------------------------------------------------------------------------------------------------------
redirector            = Redirector()
ctx._original_stdout  = sys.stdout
sys.stdout            = redirector
if ctx.get( 'log', None ) == None:
  ctx.log = lambda *P: redirector._write( redirector.pen( *P, '\n' ) )


#===========================================================================================================
# ADDONS
#-----------------------------------------------------------------------------------------------------------
if ctx.intershop_host_modules_path != ctx.intershop_guest_modules_path:
  sys.path.insert( 0, ctx.intershop_host_modules_path )
sys.path.insert( 0, ctx.intershop_guest_modules_path )
#...........................................................................................................
ctx._absorb_environment = _absorb_environment

#-----------------------------------------------------------------------------------------------------------
try:
  import intershop_main
except ImportError:
  log( "Unable to locate module `intershop_main`")
  ctx.log_python_path()
  raise
intershop_main.setup( ctx )

#-----------------------------------------------------------------------------------------------------------
def module_from_path( ctx, name, path ):
  ### thx to https://stackoverflow.com/a/50395128/7568091 ###
  ### thx to https://stackoverflow.com/a/67692/7568091 ###
  plpy.notice( '^22234-3^', "module_from_path() name: {} path: {}".format( name, path))
  import importlib
  import importlib.util
  spec                      = importlib.util.spec_from_file_location( name, path )
  module                    = importlib.util.module_from_spec( spec )
  sys.modules[ spec.name ]  = module
  spec.loader.exec_module( module )
  return  importlib.import_module( name )
#...........................................................................................................
ctx.module_from_path  = module_from_path
plpy.execute( 'select ADDONS.import_python_addons();' )

#-----------------------------------------------------------------------------------------------------------
$$;






/* ###################################################################################################### */
\quit






