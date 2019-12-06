

/*

8888888 8888888b.   .d8888b.
  888   888   Y88b d88P  Y88b
  888   888    888 888    888
  888   888   d88P 888
  888   8888888P"  888
  888   888        888    888
  888   888        Y88b  d88P
8888888 888         "Y8888P"


A library to send signals to other processes, including facilities for RPC.

The important difference to PostgreSQL's NOTIFY / LISTEN facilities is that signals are sent immediately,
independently of transactions; this is vital when what you want to do is computing insert values during a
transaction.

*/

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists IPC cascade;
create schema IPC;

-- current_database()
-- select current_setting('application_name');

-- ### TAINT consider to change name acc. to xemitter:
-- send() -> emit()
-- rpc()  -> delegate()
-- (to be used in RPC server): contract(), listen_to()

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function IPC.send( key text, value jsonb, rsvp boolean )
  returns void volatile language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import json
  ctx.ipc._write_line( json.dumps( { '$key': key, '$value': json.loads( value ), '$rsvp': rsvp, } ) )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
create function IPC.send( ¶key text, ¶value jsonb ) returns void volatile language sql as $$
  select IPC.send( ¶key, ¶value, false ); $$;

-- =========================================================================================================
-- RPC
-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function IPC.rpc( key text, value jsonb ) returns jsonb volatile language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import json
  return ctx.ipc.rpc( key, json.loads( value ) )
  $$;
reset role;



