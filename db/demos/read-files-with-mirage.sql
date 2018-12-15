

-- ---------------------------------------------------------------------------------------------------------
\pset pager off
\set ECHO none
\ir '../010-trm.sql'
-- vacuum;
begin transaction;

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _DEMO_MIRAGE_ cascade;
create schema _DEMO_MIRAGE_;


\pset pager on

/* To announce a datasource, call `MIRAGE.procure_dsk_pathmode()` (yes, this is a
  strange name that may change in the future); again, returns number of data
  sources affected; a no-op if that DSK already existed with that combo of path
  and mode (i.e. format): */

select MIRAGE.procure_dsk_pathmode(
  'demo1',                                           -- Data Source Key, read dis-kee
  ¶format( '%s/README.md', 'intershop/guest/path' ), -- file path, use literal or config values
  'plain' );                                         -- file format, 'plain' is 'just text, no fields'

/* It is always necessary to explicitly refresh a MIRAGE datasource. NB that this
  will perform a `sha1sum` against the file and otherwise do nothing if file
  contents are up-to-date in the DB. Otherwise—if the DSK is new or file
  contents have changed, it will update `MIRAGE.cache`: */

select MIRAGE.refresh( 'demo1' );

/* One can also refresh all currently known datasources: */

-- select MIRAGE.refresh();

/* After procuring and refreshing a Mirage DSK, we're now ready to access file
  contents via `MIRAGE.mirror`. We filter by DSK and order, essentially, by line
  numbers. The `order by dsk, dsnr, linenr` is just there to cover cases where
  you have (1) filtered for more than one DSK; (2) a given DSK consists of more
  than a single file (yes, that's possible):*/

select
    *
  from MIRAGE.mirror
  where dsk = 'demo1'
  order by dsk, dsnr, linenr;

/* To remove a datasource, call `MIRAGE.delete_dsk()`; returns number of data
  sources deleted (you will probably not normally do this). */

select MIRAGE.delete_dsk( 'demo1' );

\quit



\set ECHO queries
do $$ begin perform ¶( 'intershop/mirage/test1/path', ¶format( '%s/mirage-test-1', 'intershop/tmp/path' ) ); end; $$;
do $$ begin perform ¶( 'intershop/mirage/test2/path', ¶format( '%s/mirage-test-2', 'intershop/tmp/path' ) ); end; $$;
do $$ begin perform ¶( 'intershop/mirage/test3/path', ¶format( '%s/mirage-test-3', 'intershop/tmp/path' ) ); end; $$;

-- do $$ begin perform _DEMO_MIRAGE_.truncate_file( ¶( 'intershop/mirage/test1/path' ) );  end; $$;
-- do $$ begin perform _DEMO_MIRAGE_.truncate_file( ¶( 'intershop/mirage/test2/path' ) );  end; $$;
-- do $$ begin perform _DEMO_MIRAGE_.truncate_file( ¶( 'intershop/mirage/test3/path' ) );  end; $$;
-- do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test1/path' ), e'helo\t42', e'world', e'', e'# comment', e'a-key\tsome-value' );  end; $$;
-- do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test2/path' ), e'helo\t42', e'world', e'', e'# comment', e'a-key\tsome-value' );  end; $$;
-- do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test3/path' ), e'first-field\tsubsequent fields' );  end; $$;
-- do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test3/path' ), e'first-field\tsubsequent fields # with comment' );  end; $$;

select MIRAGE.add_dsk_pathmode( 'source-A', ¶( 'intershop/mirage/test1/path' ), 'cbtsv' );
select MIRAGE.add_dsk_pathmode( 'source-A', ¶( 'intershop/mirage/test2/path' ), 'cbtsv' );
select MIRAGE.add_dsk_pathmode( 'source-C', ¶( 'intershop/mirage/test3/path' ), 'cbwsv1' );
select MIRAGE.add_dsk_pathmode( 'source-C', ¶( 'intershop/mirage/test2/path' ), 'cbwsv1' );

\echo :orange'---==( 1 )==---':reset
select * from MIRAGE.modes_overview;
select * from MIRAGE.dsks;
select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.all_pathmodes;

\echo :orange'---==( 2 )==---':reset
select MIRAGE.refresh();
select * from MIRAGE.cache  order by ch, linenr;
select * from MIRAGE.mirror order by dsk, dsnr, linenr;

\echo :orange'---==( 3 )==---':reset
-- do $$ begin perform _DEMO_MIRAGE_.write( ¶( 'intershop/mirage/test2/path' ), e'another line that changes the content hash' );  end; $$;

select MIRAGE.refresh();
select * from MIRAGE.cache  order by ch, linenr;
select * from MIRAGE.mirror order by dsk, dsnr, linenr;

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
select * from MIRAGE.mirror order by dsk, dsnr, linenr;

\set ECHO none
\quit

do $$ begin perform MIRAGE.thaw_cache();    end; $$;
truncate MIRAGE.cache;
do $$ begin perform MIRAGE.freeze_cache();  end; $$;
select * from MIRAGE.mirror order by dsk, dsnr, linenr;

/* Simpler with the `MIRAGE.clear_cache()` method: */
do $$ begin perform MIRAGE.clear_cache();  end; $$;

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


