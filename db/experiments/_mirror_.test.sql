


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
create function _MIRROR_test.write_to_testfile( path_ text ) returns void stable strict
  language plpython3u as $$
  with open( path_, 'wb' ) as o:
    o.write( 'here goes text\n'.encode( 'utf-8' ) + b'\n' )
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _MIRROR_test.append_to_testfile( path_ text ) returns void stable strict
  language plpython3u as $$
  with open( path_, 'ab' ) as o:
    o.write( 'some text here\n#comment\n'.encode( 'utf-8' ) + b'\n' )
  $$;
reset role;


/* ###################################################################################################### */

-- select _MIRROR_test.f();

/*
touch /tmp/testfile_1 && chmod 666 /tmp/testfile_1 && touch /tmp/testfile && chmod 666 /tmp/testfile

*/


do $$ begin perform _MIRROR_test.write_to_testfile( '/tmp/testfile_1' );  end; $$;
do $$ begin perform _MIRROR_test.write_to_testfile( '/tmp/testfile' );    end; $$;
do $$ begin perform _MIRROR_test.append_to_testfile( '/tmp/testfile' );   end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );            end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile' );              end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.parameters_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none
--\quit

do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile', '{"skip":true}' );            end; $$;
-- do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );          end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.parameters_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none
\quit

do $$ begin perform _MIRROR_test.append_to_testfile( '/tmp/testfile_1' ); end; $$;
do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );            end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.parameters_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none

do $$ begin perform _MIRROR_.cache_lines( '/tmp/testfile_1' );            end; $$;

\set ECHO queries
select * from _MIRROR_.chs;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.parameters_and_chs;
select * from _MIRROR_.lines limit 15;
\set ECHO none

\set ECHO queries
select _MIRROR_._ch_from_text_diagnostic( 'helo'  ) as "A", _MIRROR_.ch_from_text( 'helo' ) as "B";
select _MIRROR_._ch_from_text_diagnostic( ''      ) as "A", _MIRROR_.ch_from_text( ''     ) as "B";
\set ECHO none


\quit


-- -- select ¶( 'intershop/paths/app' );
-- select ¶( '_mirror_/paths/readme', ¶( 'intershop/paths/app' ) || '/README.md' );
-- select _MIRROR_.cache_lines( ¶( '_mirror_/paths/readme' ) );
-- select _MIRROR_.content_hash_from_path( ¶( '_mirror_/paths/readme' ) ) as ch;
-- select * from _MIRROR_.paths_and_chs;
-- select * from _MIRROR_.parameters_and_chs;
-- select * from _MIRROR_.lines limit 15;


