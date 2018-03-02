




-- ---------------------------------------------------------------------------------------------------------
\pset pager off
\ir '../010-trm.sql'
-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _INTERPOL_ cascade;
create schema _INTERPOL_;

-- ---------------------------------------------------------------------------------------------------------
create function _INTERPOL_.¶resolve( ¶template text ) returns text stable strict language plpgsql as $$
  declare
    R text  := '';
  begin
    perform log( '44452', regexp_split_to_array( ¶template, '(?<!\\)\${' )::text );
    return R;
    end; $$;

/*
-- ---------------------------------------------------------------------------------------------------------
create function _INTERPOL_.¶format( ¶template text, variadic ¶values text[] )
  returns text stable strict language plpgsql as $$
  begin
    ¶values :=  array_agg( ¶( key ) ) from unnest( ¶values ) as key;
    return format( ¶template, variadic ¶values );
    end; $$;
*/

-- ---------------------------------------------------------------------------------------------------------
create function _INTERPOL_.¶format( ¶template text, variadic ¶values text[] )
  returns text stable strict language sql as $$
    select format( ¶template, variadic ( select array_agg( ¶( key ) ) from unnest( ¶values ) as key ) );
    $$;

select * from U.variables where key ~ '^intershop' order by key;
select ¶( 'intershop/db/name' );
select _INTERPOL_.¶resolve( 'welcome to ${intershop/db/name} (not \${Lemuria})!!!' );
select _INTERPOL_.¶resolve( '${intershop/db/port}' );
select _INTERPOL_.¶resolve( '${intershop/db/port}${intershop/db/user}' );
select _INTERPOL_.¶resolve( '${intershop/db/port}\${intershop/db/user}' );

select format( 'welcome to %s (not %%sLemuria!!!', 'intershop/db/name' );
select _INTERPOL_.¶format( 'welcome to %s (not %%sLemuria)!!!', 'intershop/db/name' );
select _INTERPOL_.¶format( 'connecting to %s:%s', 'intershop/rpc/host', 'intershop/rpc/port' );
-- select format( '${intershop/db/port}' );
-- select format( '${intershop/db/port}${intershop/db/user}' );
-- select format( '${intershop/db/port}\${intershop/db/user}' );


\quit


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _DEMO_MIRAGE_.write_to_testfile( path_ text )
  returns void stable strict language plpython3u as $$
  with open( path_, 'wb' ) as o:
    o.write( 'here goes text\n'.encode( 'utf-8' ) + b'\n' )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _DEMO_MIRAGE_.append_to_testfile( path_ text )
  returns void stable strict language plpython3u as $$
  import datetime
  with open( path_, 'ab' ) as o:
    line = 'some text here {:%Y-%m-%d %H:%M:%S}'.format( datetime.datetime.now() )
    o.write( line.encode( 'utf-8' ) + b'\n' )
  $$;
reset role;



-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
-- \set ECHO all

\pset pager on
\set ECHO all
-- select * from MIRAGE.chs;
-- select * from MIRAGE.paths;

\echo :orange'---==( 1 )==---':reset
select * from MIRAGE.dsks;
select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.all_pathmodes;
\echo :orange'---==( 2 )==---':reset
select MIRAGE.delete_dsk( 'demo' );
select MIRAGE.add_dsk_pathmode( 'demo', '/home/flow/io/sqlite-demo/data/a-few-naive-formulas.txt', 'cbtsv' );
select MIRAGE.add_dsk_pathmode( 'demo', '/home/flow/io/sqlite-demo/data/a-few-naive-formulas-B.txt', 'cbtsv' );
select MIRAGE.delete_dsk( 'formulas' );
select MIRAGE.add_dsk_pathmode( 'formulas', '/home/flow/io/mingkwai-rack/jzrds/shape/shape-breakdown-formula-naive.txt', 'cbtsv' );
select MIRAGE.add_dsk_pathmode( 'formulas', '/home/flow/io/mingkwai-rack/jzrds/shape/shape-breakdown-formula-v2.txt', 'cbtsv' );

select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.all_pathmodes;
\echo :orange'---==( 3 )==---':reset
\timing on
select MIRAGE.refresh_cache();
-- select count(*) from MIRAGE.cache;
-- select count(*) from MIRAGE.mirror;
\set ECHO none
\quit

\set ECHO all
select * from MIRAGE.chs;
select * from MIRAGE.dsks;
-- select * from MIRAGE.paths;
-- select * from MIRAGE.modes;
select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.paths_and_chs;
select * from MIRAGE.cache;
\set ECHO none


\quit

\echo :orange'---==( 4 )==---':reset
select
  MIRAGE.refresh_cache( path, 'plain' )
  from MIRAGE.paths;

\set ECHO all
select * from MIRAGE.chs;
select * from MIRAGE.dsks;
-- select * from MIRAGE.paths;
-- select * from MIRAGE.modes;
select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.paths_and_chs;
-- select * from MIRAGE.cache;
\set ECHO none

\echo :orange'---==( 5 )==---':reset
-- do $$ begin perform _DEMO_MIRAGE_.append_to_testfile( '/home/flow/io/sqlite-demo/data/a-few-naive-formulas.txt' );   end; $$;

\echo :orange'---==( 6 )==---':reset
select
  MIRAGE.refresh_cache( path, 'plain' )
  from MIRAGE.paths;

\set ECHO all
select * from MIRAGE.chs;
select * from MIRAGE.dsks;
-- select * from MIRAGE.paths;
-- select * from MIRAGE.modes;
select * from MIRAGE.dsks_and_pathmodes;
select * from MIRAGE.paths_and_chs;
-- select * from MIRAGE.cache;
\set ECHO none


\quit
/* ====================================================================================================== */





create table _DEMO_MIRAGE_.paths ( path text not null );
insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-breakdown-formula-naive.txt'                 );
-- insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-breakdown-formula-v2.txt'                    );
-- insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-factor-hierarchy.txt'                        );
-- insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-figural-themes.txt'                          );
-- insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-guides-similarity.txt'                       );
-- insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-similarity-identity.txt'                     );
-- insert into _DEMO_MIRAGE_.paths values ( 'shape/shape-strokeorder-zhaziwubifa.txt'                 );
-- insert into _DEMO_MIRAGE_.paths values ( 'meaning/meanings.txt'                                    );
-- insert into _DEMO_MIRAGE_.paths values ( 'other-systems/guoxuedashi.com/guoxuedashi-factors.txt'   );
-- insert into _DEMO_MIRAGE_.paths values ( 'other-systems/kangxi/wikipedia-kangxi.txt'               );
-- insert into _DEMO_MIRAGE_.paths values ( 'other-systems/kanshudo.com/kanshudo-components.txt'      );
-- insert into _DEMO_MIRAGE_.paths values ( 'other-systems/shuowen/shuowen.txt'                       );
-- insert into _DEMO_MIRAGE_.paths values ( 'other-systems/zdic.net/zdic-factors.txt'                 );
-- insert into _DEMO_MIRAGE_.paths values ( 'usage/usage-sawndip.txt'                                 );
-- insert into _DEMO_MIRAGE_.paths values ( 'variantusage/variants-and-usage.txt'                     );


-- select _DEMO_MIRAGE_.count_text_filelines( :'path' );

/* # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  */
/*  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # */
/* # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  */
/*  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # */


/*
touch /tmp/testfile_1 && chmod 666 /tmp/testfile_1 && touch /tmp/testfile && chmod 666 /tmp/testfile

*/


do $$ begin perform _DEMO_MIRAGE_.write_to_testfile( '/tmp/testfile_1' );  end; $$;
do $$ begin perform _DEMO_MIRAGE_.write_to_testfile( '/tmp/testfile' );    end; $$;
do $$ begin perform _DEMO_MIRAGE_.append_to_testfile( '/tmp/testfile' );   end; $$;
do $$ begin perform _MIRAGE_.cache_lines( '/tmp/testfile_1' );            end; $$;
do $$ begin perform _MIRAGE_.cache_lines( '/tmp/testfile' );              end; $$;

