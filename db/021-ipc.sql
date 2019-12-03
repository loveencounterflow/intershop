
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


/*
                                888
                                888
                                888
.d8888b   .d88b.  88888b.   .d88888
88K      d8P  Y8b 888 "88b d88" 888
"Y8888b. 88888888 888  888 888  888
     X88 Y8b.     888  888 Y88b 888
 88888P'  "Y8888  888  888  "Y88888

*/

-- ---------------------------------------------------------------------------------------------------------
-- create function IPC.send(                             data unknown    ) returns void volatile language plpgsql as $$ begin perform IPC._send( 'all',    'data',  'q', data::text  ); end; $$;
create function IPC.send(                             data anyelement ) returns void volatile language plpgsql as $$ begin perform IPC._send( 'all',    'data',  'q', data        ); end; $$;
-- create function IPC.send( channel text,               data unknown    ) returns void volatile language plpgsql as $$ begin perform IPC._send( channel,  'data',  'q', data::text  ); end; $$;
create function IPC.send( channel text,               data text       ) returns void volatile language plpgsql as $$ begin perform IPC._send( channel,  'data',  'q', data        ); end; $$;
create function IPC.send( channel text,               data anyelement ) returns void volatile language plpgsql as $$ begin perform IPC._send( channel,  'data',  'q', data        ); end; $$;
-- create function IPC.send( channel text, command text, data unknown    ) returns void volatile language plpgsql as $$ begin perform IPC._send( channel,  command, 'q', data::text  ); end; $$;
create function IPC.send( channel text, command text, data text       ) returns void volatile language plpgsql as $$ begin perform IPC._send( channel,  command, 'q', data        ); end; $$;
create function IPC.send( channel text, command text, data anyelement ) returns void volatile language plpgsql as $$ begin perform IPC._send( channel,  command, 'q', data        ); end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT this function should be written in Python and call IPC._send from the ipc module;
  we only have it here b/c type `anyelement` is not an allowed plpython3u function parameter type. */
create function IPC._send( channel text, command text, role text, data anyelement )
  returns void volatile language plpgsql as $$
    begin
      perform IPC._write_line( jsonb_build_object(
        'channel',  channel,
        'command',  command,
        'role',     role,
        'data',     data
        )::text );
      end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT this function should only exist in Python module */
set role dba;
create function IPC._write_line( line text ) returns void volatile language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  return ctx.ipc._write_line( line )
  $$;
reset role;


/*

8888888b.  8888888b.   .d8888b.
888   Y88b 888   Y88b d88P  Y88b
888    888 888    888 888    888
888   d88P 888   d88P 888
8888888P"  8888888P"  888
888 T88b   888        888    888
888  T88b  888        Y88b  d88P
888   T88b 888         "Y8888P"

*/

-- ---------------------------------------------------------------------------------------------------------
create function IPC.rpc( method text, parameters jsonb ) returns jsonb volatile language plpgsql as $$
  begin
    return IPC._rpc( method, parameters );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function IPC._rpc( method text, parameters jsonb )
  returns text volatile language plpgsql as $$
    declare
      R text;
    begin
      perform IPC._send( channel, 'rpc', jsonb_build_object( 'method', method, 'parameters', parameters ) );
      R := IPC._read_line();
      return R;
      end; $$;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function IPC._read_line() returns text volatile language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  return ctx.ipc._read_line()
  $$;
reset role;

