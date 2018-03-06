

-- ---------------------------------------------------------------------------------------------------------
\pset pager off
\set ECHO none
\ir '../010-trm.sql'
-- vacuum;

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _DEMO_MIRAGE_ cascade;
create schema _DEMO_MIRAGE_;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _DEMO_MIRAGE_.truncate_file( path_ text )
  returns void stable strict language plpython3u as $$
  with open( path_, 'wb' ) as o: o.write( b'' )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _DEMO_MIRAGE_.write( path_ text, variadic lines_ text[] )
  returns void stable strict language plpython3u as $$
  with open( path_, 'ab' ) as o:
    for line in lines_:
      o.write( line.encode( 'utf-8' ) + b'\n' )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _DEMO_MIRAGE_.write_with_timestamp( path_ text, variadic lines_ text[] )
  returns void stable strict language plpython3u as $$
  def tstamp(): import datetime; return '{:%Y-%m-%d %H:%M:%S}'.format( datetime.datetime.now() )
  with open( path_, 'ab' ) as o:
    for line in lines_:
      line = '{0}\t{1}'.format( tstamp(), line )
      o.write( line.encode( 'utf-8' ) + b'\n' )
  $$;
reset role;

-- select _DEMO_MIRAGE_.refresh( 'meanings' );
-- select _DEMO_MIRAGE_.refresh( null );
-- select _DEMO_MIRAGE_.refresh( 'sims' );
-- \quit

-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
-- \set ECHO queries

\pset pager off
-- select * from MIRAGE.chs;
-- select * from MIRAGE.paths;





\set ECHO queries
do $$ begin perform ¶( 'intershop/mirage/test1/path', ¶format( '%s/mirage-test-1', 'intershop/tmp/path' ) ); end; $$;
do $$ begin perform ¶( 'intershop/mirage/test2/path', ¶format( '%s/mirage-test-2', 'intershop/tmp/path' ) ); end; $$;

do $$ begin perform _DEMO_MIRAGE_.truncate_file( ¶( 'intershop/mirage/test1/path' ) );  end; $$;
do $$ begin perform _DEMO_MIRAGE_.truncate_file( ¶( 'intershop/mirage/test2/path' ) );  end; $$;
do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test1/path' ), e'helo\t42', e'world', e'', e'# comment', e'a-key\tsome-value' );  end; $$;
do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test2/path' ), e'helo\t42', e'world', e'', e'# comment', e'a-key\tsome-value' );  end; $$;

select MIRAGE.add_dsk_pathmode( 'source-A', ¶( 'intershop/mirage/test1/path' ), 'cbtsv' );
select MIRAGE.add_dsk_pathmode( 'source-A', ¶( 'intershop/mirage/test2/path' ), 'cbtsv' );

\echo :orange'---==( 1 )==---':reset
select * from MIRAGE.modes_overview;
select * from MIRAGE.dsks;
select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.all_pathmodes;

\echo :orange'---==( 2 )==---':reset
select MIRAGE.refresh();
select * from MIRAGE.cache  order by ch, linenr;
select * from MIRAGE.mirror order by dsk, nr, linenr;

\echo :orange'---==( 3 )==---':reset
do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test2/path' ), e'another line that changes the content hash' );  end; $$;

select MIRAGE.refresh();
select * from MIRAGE.cache  order by ch, linenr;
select * from MIRAGE.mirror order by dsk, nr, linenr;

\echo :orange'---==( 4 )==---':reset
/* The preferred method to add data source keys (DSKs) and pathmodes is to 'procure' them; this will
  implicitly add the DSK where it is missing and associate the pathmode with the given DSK where that
  association is missing; otheriwse, it will do nothing. The return value of `MIRAGE.procure_dsk_pathmode`
  is `1` when a new ( DSK, pathmode ) pair has been added, and `0` otherwise: */
select * from MIRAGE.dsks_and_pathmodes;
select MIRAGE.procure_dsk_pathmode( 'source-B', ¶( 'intershop/mirage/test2/path' ), 'wsv' );
select MIRAGE.procure_dsk_pathmode( 'source-B', ¶( 'intershop/mirage/test2/path' ), 'wsv' );
select * from MIRAGE.dsks_and_pathmodes;
/* Only when `MIRAGE.enforce_unique_dsk_paths( false )` has been used to remove the uniqueness constraint
  on pairs ( DSK, path ) can we add the same path again to a given DSK: */
do $$ begin perform MIRAGE.enforce_unique_dsk_paths( false ); end; $$;
select MIRAGE.add_dsk_pathmode( 'source-B', ¶( 'intershop/mirage/test2/path' ), 'wsv' );
select * from MIRAGE.dsks_and_pathmodes;
select MIRAGE.refresh();
select * from MIRAGE.mirror order by dsk, nr, linenr;

\set ECHO none
\quit

/* ###################################################################################################### */

\echo :orange'---==( 4 )==---':reset
-- ---------------------------------------------------------------------------------------------------------
do $$ begin perform MIRAGE.thaw_cache();    end; $$;
delete from MIRAGE.mode_actors    where actor = 'trim';
delete from MIRAGE.modes          where mode  = 'jzrtsv';
do $$ begin perform MIRAGE.freeze_cache();  end; $$;
insert into MIRAGE.mode_actors  values ( 'trim', 'user', 'something' );
insert into MIRAGE.modes          values  ( 'jzrtsv', array[ 'tab', 'trim' ] );

-- ---------------------------------------------------------------------------------------------------------
select * from MIRAGE.mode_actors;
select * from MIRAGE.modes;
select * from MIRAGE.modes as mo left join MIRAGE.mode_actors as mp on ( mp.actor = any ( select unnest( mo.actors ) ) );
select * from MIRAGE.modes_overview;


