
drop type if exists U.ch_line_facet cascade;
create type U.ch_line_facet as ( ch text, linenr integer,  line  text      );


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _MIRROR_ cascade;
create schema _MIRROR_;

-- ---------------------------------------------------------------------------------------------------------
create table _MIRROR_.paths_and_chs (
  path  text unique not null,
  ch    text unique not null,
  primary key ( path, ch ) );

-- ---------------------------------------------------------------------------------------------------------
create table _MIRROR_.lines (
  ch      text    not null,           /* ### TAINT use CH domain */
  linenr  integer not null,           /* ### TAINT must be >= 1, consecutive */
  line    text    not null,
  primary key ( ch, linenr ) );

-- ---------------------------------------------------------------------------------------------------------
set role dba;
/* ### TAINT use CH domain */
create function _MIRROR_._content_hash_from_path( ¶path text ) returns text stable strict
  language plsh as $$#!/bin/bash
  sha1sum "$1" | cut --characters=-17
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create function _MIRROR_.content_hash_from_path( ¶path text ) returns text volatile strict
  language plpgsql as $$
  declare
    R text := _MIRROR_._content_hash_from_path( ¶path );
  begin
    insert into _MIRROR_.paths_and_chs ( path, ch ) values ( ¶path, R )
      on conflict ( path, ch ) do update set ch = R;
    return R;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
-- create function _MIRROR_.read( ¶path text ) returns setof U.ch_line_facet volatile strict
/* ### TAINT use CH domain */
create function _MIRROR_.read( ¶path text ) returns void volatile strict
  language plpgsql as $$
  declare
    ¶ch   text  :=  _MIRROR_.content_hash_from_path( ¶path );
  begin
    delete from _MIRROR_.lines where ch = ¶ch;
    insert into _MIRROR_.lines ( ch, linenr, line )
      select ¶ch, r.linenr, r.line
      from FILELINEREADER.read_lines( ¶path ) as r;
    end;
  $$;


/* ###################################################################################################### */



-- select ¶( 'intershop/paths/app' );
select ¶( '_mirror_/paths/readme', ¶( 'intershop/paths/app' ) || '/README.md' );
select _MIRROR_.read( ¶( '_mirror_/paths/readme' ) );
select _MIRROR_.content_hash_from_path( ¶( '_mirror_/paths/readme' ) ) as ch;
select * from _MIRROR_.paths_and_chs;
select * from _MIRROR_.lines limit 15;



