


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _MIRROR_test cascade;
create schema _MIRROR_test;

-- -- ---------------------------------------------------------------------------------------------------------
-- set role dba;
-- create function _MIRROR_test.f( ) returns text stable strict
--   language plsh as $$#!/bin/bash
--   realpath '$1'
--   $$;
-- reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _MIRROR_test.write_to_testfile( ¶path text ) returns void stable strict
  language plsh as $$#!/bin/bash
  sudo -u flow echo 'helo world' > "$1"
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _MIRROR_test.append_to_testfile( ¶path text ) returns void stable strict
  language plsh as $$#!/bin/bash
  echo 'and then some' >> "$1"
  $$;
reset role;


/* ###################################################################################################### */

-- select _MIRROR_test.f();

do $$ begin perform _MIRROR_test.write_to_testfile( '/tmp/testfile_1' );  end; $$;
do $$ begin perform _MIRROR_test.write_to_testfile( '/tmp/testfile' );    end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );            end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile' );              end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none


do $$ begin perform _MIRROR_test.append_to_testfile( '/tmp/testfile' ); end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile' );            end; $$;
-- do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );          end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none

do $$ begin perform _MIRROR_test.append_to_testfile( '/tmp/testfile_1' ); end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );            end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none

do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );            end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none


\quit


-- -- select ¶( 'intershop/paths/app' );
-- select ¶( '_mirror_/paths/readme', ¶( 'intershop/paths/app' ) || '/README.md' );
-- select _MIRROR_.cache_lines( ¶( '_mirror_/paths/readme' ) );
-- select _MIRROR_.content_hash_from_path( ¶( '_mirror_/paths/readme' ) ) as ch;
-- select * from _MIRROR_.paths_and_chs;
-- select * from _MIRROR_.lines limit 15;


