
drop type if exists U.ch_line_facet cascade;
create type U.ch_line_facet as ( ch text, linenr integer,  line  text      );


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _MIRROR_ cascade;
create schema _MIRROR_;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create table _MIRROR_.chs (
  ch    text unique not null primary key );

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create table _MIRROR_.paths_and_chs (
  path  text unique not null,
  ch    text not null references _MIRROR_.chs ( ch ) on delete cascade,
  primary key ( path, ch ) );

-- -- ---------------------------------------------------------------------------------------------------------
-- create function _MIRROR_.on_before_update_paths_and_chs() returns trigger language plpgsql as $$
--   begin
--     perform log( '88872' );
--     delete from _MIRROR_.paths_and_chs where ch = old.ch;
--     return new; end; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- create trigger on_before_update_paths_and_chs before update on _MIRROR_.paths_and_chs
-- for each row execute procedure _MIRROR_.on_before_update_paths_and_chs();

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
/* ### TAINT linenr must be >= 1, consecutive */
create table _MIRROR_.lines (
  ch      text    not null references _MIRROR_.chs ( ch ) on delete cascade,
  linenr  integer not null,
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
/* ### TAINT unsure how delete, then insert behaves under concurrency */
create function _MIRROR_.content_hash_from_path( ¶path text ) returns text volatile strict
  language plpgsql as $$
  declare
    R       text  :=  _MIRROR_._content_hash_from_path( ¶path );
    ¶old_ch text;
  begin
    --......................................................................................................
    /* Retrieve previous CH, if any: */
    -- select into ¶old_ch ch from _MIRROR_.paths_and_chs where path = ¶path;
    ¶old_ch := ch from _MIRROR_.paths_and_chs where path = ¶path;
    --......................................................................................................
    /* Remove association between path and CH: */
    delete from _MIRROR_.paths_and_chs where path = ¶path;
    perform log( '98987', 'ch', R );
    --......................................................................................................
    /* Try to delete old CH and insert new CH: */
    delete from _MIRROR_.chs where ch = ¶old_ch;
    insert into _MIRROR_.chs ( ch ) values ( R ) on conflict do nothing;
    --......................................................................................................
    insert into _MIRROR_.paths_and_chs ( path, ch ) values ( ¶path, R );
      -- on conflict ( path, ch ) do update set ch = R;
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
    -- delete from _MIRROR_.lines where ch = ¶ch;
    insert into _MIRROR_.lines ( ch, linenr, line )
      select ¶ch, r.linenr, r.line
      from FILELINEREADER.read_lines( ¶path ) as r;
    end;
  $$;


/* ###################################################################################################### */


\ir './_mirror_.test.sql'


