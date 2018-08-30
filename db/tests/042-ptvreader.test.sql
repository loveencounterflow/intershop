

-- ---------------------------------------------------------------------------------------------------------
\ir ./start.test.sql

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _PTVREADER_ cascade;
create schema _PTVREADER_;

\pset pager on
-- \set ECHO queries
\set ECHO none


/* ###################################################################################################### */

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 1 )==---':reset
/* Here we first use the psql backtick syntax to execute command `pwd` with the shell,
which echoes the path of the current working directory. This value is put into a
temporary psql variable, and that variable is in turn used to set a session variable which can
subsequently be used inside a function and other SQL contexts: */
\set tmp `pwd` \\ set intershop.cwd = :'tmp';


-- set intershop.foo = 42 + 108;
-- select current_setting( 'intershop.foo' );

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 2 )==---':reset
create function _PTVREADER_._add_mirage_dsks_for_intershop_ptv_files()
  returns void volatile language plpgsql as $$
  declare
    ¶host_configuration_path  text := current_setting( 'intershop.cwd' ) || '/intershop.ptv';
    ¶guest_configuration_path text := current_setting( 'intershop.cwd' ) || '/intershop/intershop.ptv';
  begin
    perform set_config( 'intershop.host_configuration_path',  ¶host_configuration_path,   false );
    perform set_config( 'intershop.guest_configuration_path', ¶guest_configuration_path,  false );
    perform MIRAGE.delete_dsk( 'configuration' );
    perform MIRAGE.add_dsk_pathmode( 'configuration', ¶guest_configuration_path, 'ptv' );
    perform MIRAGE.add_dsk_pathmode( 'configuration', ¶host_configuration_path,  'ptv' );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 3 )==---':reset
do $$ begin perform _PTVREADER_._add_mirage_dsks_for_intershop_ptv_files(); end; $$;
do $$ begin perform MIRAGE.refresh( 'configuration' ); end; $$;

do $$ begin perform log( '22922', current_setting( 'intershop.cwd' ) ); end; $$;
-- \echo :red'77484':reset
-- \quit

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 4 )==---':reset
create view _PTVREADER_._ptv_0 as (
  ( select null::integer as dsnr, null::integer as linenr, null::text as key, null::text as type, null::text as value where false    ) union
  ( select 0, 1, 'intershop/cwd',                       'text/path/folder',  current_setting( 'intershop.cwd'                      ) ) union
  ( select 0, 2, 'intershop/guest/configuration/path',  'text/path/folder',  current_setting( 'intershop.guest_configuration_path' ) ) union
  ( select 0, 3, 'intershop/host/configuration/path',   'text/path/folder',  current_setting( 'intershop.host_configuration_path'  ) ) union
  ( select null, null, null, null, null where false )
  );

-- ---------------------------------------------------------------------------------------------------------
comment on view _PTVREADER_._ptv_0 is 'View on fundamental configuration values such as the
  current working directory of the calling process, location of configuration files.';

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 5 )==---':reset
create view _PTVREADER_._ptv_1 as ( select
    m.dsnr                                as dsnr,
    m.linenr                              as linenr,
    m.fields[ 1 ]                         as key,
    m.fields[ 2 ]                         as type,
    m.fields[ 3 ]                         as value
  from MIRAGE.mirror as m
  where true
    and include
    and dsk = 'configuration'
    -- and fields[ 1 ] ~ '^mojikura/mirage/dsk/'
  order by dsnr, linenr );

-- ---------------------------------------------------------------------------------------------------------
comment on view _PTVREADER_._ptv_0 is 'View on configuration files.';

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create view _PTVREADER_._ptv_2 as (
  ( select * from _PTVREADER_._ptv_0 ) union
  ( select * from _PTVREADER_._ptv_1 )
  order by dsnr, linenr );

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create function _PTVREADER_.refresh_configuration()
  returns void volatile language plpgsql as $$
  declare
  begin
    end; $$;

do $$ begin perform _PTVREADER_.refresh_configuration(); end; $$;


/* ====================================================================================================== */
-- select * from _PTVREADER_._ptv_2;

-- select cast( value as type ) from ( select
--   '123'::text, 'integer'::text ) as q1 ( value, type )
--   ;

/* ====================================================================================================== */
\quit

/* doesn't work: 'A function returning a polymorphic type must have at least one polymorphic argument.' */
-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( 6 )==---':reset
create function cast_as( ¶value text, ¶type text )
  returns anyelement immutable parallel safe language plpgsql as $$
  declare
    R anyelement;
  begin
    execute format( 'cast( %L as %s )', ¶value, ¶type ) into R;
    return R;
    end $$;

select cast_as( '23', 'integer', 0 );
