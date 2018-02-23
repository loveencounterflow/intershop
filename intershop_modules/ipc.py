
"""

8888888 8888888b.   .d8888b.
  888   888   Y88b d88P  Y88b
  888   888    888 888    888
  888   888   d88P 888
  888   8888888P"  888
  888   888        888    888
  888   888        Y88b  d88P
8888888 888         "Y8888P"

"""

#-----------------------------------------------------------------------------------------------------------
import socket as _SOCKET
import os     as _OS
import json   as _JSON
_cache = {}

#-----------------------------------------------------------------------------------------------------------
def _prepare():
  if _cache.get( 'SIGNALS.client_socket_rfile', None ) != None: return
  client_socket                       = _SOCKET.socket( _SOCKET.AF_INET, _SOCKET.SOCK_STREAM )
  client_socket.connect( ( ctx.intershop_rpc_host, ctx.intershop_rpc_port, ) )
  client_socket_rfile                 = _OS.fdopen( client_socket.fileno(), 'r', encoding = 'utf-8' )
  _cache[ 'SIGNALS.client_socket'       ] = client_socket
  _cache[ 'SIGNALS.client_socket_rfile' ] = client_socket_rfile
  # _write_line( '{"data":"helo","role":"q","channel":"all","command":"helo"}' )
  rpc( 'helo', [ 'some', 'data', ] )

#-----------------------------------------------------------------------------------------------------------
def _write_line( line ):
  _prepare()
  line_b = str.encode( line + '\n' )
  _cache[ 'SIGNALS.client_socket' ].send( line_b )

#-----------------------------------------------------------------------------------------------------------
def _read_line():
  return _cache[ 'SIGNALS.client_socket_rfile' ].readline().strip()

#-----------------------------------------------------------------------------------------------------------
### TAINT must implement RPC result buffer ###
def rpc( method, parameters ):
  _write_line( _JSON.dumps( [ method, parameters, ] ) )
  try:
    R = _JSON.loads( _read_line() )
    command   = R[ 0 ]
    data      = R[ 1 ]
  except Exception:
    raise
  return R






