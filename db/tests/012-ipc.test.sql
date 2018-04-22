


/* ###################################################################################################### */
\ir './start.test.sql'
-- \pset pager on
\timing on

begin transaction;
drop schema if exists _IPC_ cascade;
create schema _IPC_;
-- drop schema if exists SIEVE cascade;
-- \ir '../055-sieve.sql'
-- commit;
-- \quit


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _IPC_.add( n1 float, n2 float ) returns float language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  return ctx.ipc.rpc( 'add', [ n1, n2, ] )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _IPC_.add_integers_only( n1 float, n2 float ) returns text language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  return ctx.ipc.rpc( 'add_integers_only', [ n1, n2, ] )
  $$;
reset role;


-- ---------------------------------------------------------------------------------------------------------
select _IPC_.add( 23, 54 ) union all
select _IPC_.add( 123, 54 ) union all
select null where false;

-- ---------------------------------------------------------------------------------------------------------
select _IPC_.add_integers_only( 23, 54 ) union all
select _IPC_.add_integers_only( 123, 54 ) union all
select _IPC_.add_integers_only( 123.1, 54 ) union all
select null where false;

/* ###################################################################################################### */
rollback transaction;
\ir './stop.test.sql'




