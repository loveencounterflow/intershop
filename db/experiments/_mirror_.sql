


-- \set ECHO queries
-- -- select ( '{"skip":true}'::json )->'skip'    = 'true'::json;
-- select ( '{"skip":true}'::json )->>'skip'   = 'true';
-- select ( '{"skip":"true"}'::json )->>'skip' = 'true';
-- select ( '{"skip":"true"}'::jsonb ) @> ( '{"skip":"true"}'::jsonb );
-- \set ECHO none

-- \quit



drop type if exists U.ch_line_facet cascade;
drop function if exists FILELINEREADER.read_lines( text, json ) cascade;
drop schema if exists _MIRROR_ cascade;

-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

-- ---------------------------------------------------------------------------------------------------------
create type U.ch_line_facet as ( ch text, linenr integer,  line  text      );

-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

-- ---------------------------------------------------------------------------------------------------------
create function FILELINEREADER.read_lines( ¶path text, ¶parameters json ) returns setof U.line_facet
  stable language plpgsql as $$
  declare
    ¶parameters_jb  jsonb :=  ¶parameters::jsonb;
  begin
    case when ¶parameters_jb @> '{"skip":true}'::jsonb then
      raise notice '98721 reading % with read_lines_skip', ¶path;
      return query select * from FILELINEREADER.read_lines_skip( ¶path );
    else
      raise notice '98721 reading % with read_lines', ¶path;
      return query select * from FILELINEREADER.read_lines( ¶path );
      end case;
    end;
  $$;


-- ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

-- ---------------------------------------------------------------------------------------------------------
create schema _MIRROR_;

-- ---------------------------------------------------------------------------------------------------------
/* Type for content hashes: */
drop domain if exists _MIRROR_.content_hash cascade;
create domain _MIRROR_.content_hash as character( 17 ) check ( value ~ '^[0-9a-f]{17}$' );
comment on domain _MIRROR_.content_hash is
  'type for content hashes (currently: leading 17 lower case hex digits of SHA1 hash digest)';

-- -- ---------------------------------------------------------------------------------------------------------
-- create function _MIRROR_.is_valid_ch( ¶x text )
--   returns boolean language sql strict immutable as $$
--     select ¶x ~ '^[0-9a-f]{17}$'; $$;

-- ---------------------------------------------------------------------------------------------------------
create function _MIRROR_.ch_from_text( text ) returns _MIRROR_.content_hash language sql immutable strict as $$
  select (
    substring(
      encode(
        _pgcrypto.digest( $1::bytea, 'sha1' ), 'hex' ) from 1 for 17 ) )::_MIRROR_.content_hash; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create table _MIRROR_.chs (
  ch text unique not null primary key );

-- ---------------------------------------------------------------------------------------------------------
alter table _MIRROR_.chs
  add constraint "CHs must consist of 17 lower case hexdigits"
  check ( ch::_MIRROR_.content_hash = ch );

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create table _MIRROR_.paths_and_chs (
  path        text not null unique,
  ch          text not null references _MIRROR_.chs ( ch ) on delete cascade,
  primary key ( path, ch ) );

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create table _MIRROR_.parameters_and_chs (
  parameters  text not null unique,
  ch          text not null unique references _MIRROR_.chs ( ch ) on delete cascade,
  primary key ( parameters, ch ) );

-- insert into _MIRROR_.chs                  values  ( '111' ), ( '222' ), ( '333' );
-- insert into _MIRROR_.paths_and_chs        values  ( 'path1', '111' );
-- insert into _MIRROR_.paths_and_chs        values  ( 'path2', '222' );
-- insert into _MIRROR_.parameters_and_chs   values  ( 'parameter2', '222' );
-- insert into _MIRROR_.parameters_and_chs   values  ( 'parameter3', '333' );

-- ---------------------------------------------------------------------------------------------------------
create view _MIRROR_.paths_parameters_and_chs as (
  select
      fchs.path       as path,
      null::text      as parameters,
      fchs.ch         as ch
    from _MIRROR_.paths_and_chs as fchs
  union
  select
      null::text      as paths,
      pchs.parameters as parameters,
      pchs.ch         as ch
    from _MIRROR_.parameters_and_chs as pchs
  order by ch, path );

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
/* ### TAINT linenr must be >= 1, but not necessarily be consecutive (when file is filtered on reading) */
create table _MIRROR_.lines (
  fch     text    not null references _MIRROR_.chs ( ch ) on delete cascade,
  pch     text    not null references _MIRROR_.chs ( ch ) on delete cascade,
  linenr  integer not null,
  line    text    not null,
  primary key ( fch, pch, linenr ) );

-- ---------------------------------------------------------------------------------------------------------
set role dba;
/* ### TAINT use CH domain */
create function _MIRROR_._ch_from_path( ¶path text ) returns text stable strict
  language plsh as $$#!/bin/bash
  sha1sum "$1" | cut --characters=-17
  $$;

-- ---------------------------------------------------------------------------------------------------------
create function _MIRROR_._ch_from_text_diagnostic( ¶text text ) returns text stable strict
  language plsh as $$#!/bin/bash
  printf "$1" | sha1sum | cut --characters=-17
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
create function _MIRROR_._ch_from_parameters( ¶parameters text )
  returns _MIRROR_.content_hash volatile strict language plpgsql as $$
  declare
    ¶R  _MIRROR_.content_hash :=  _MIRROR_.ch_from_text( ¶parameters );
  begin
    insert into _MIRROR_.chs ( ch ) values ( ¶R )
      on conflict do nothing;
    insert into _MIRROR_.parameters_and_chs ( parameters, ch ) values ( ¶parameters, ¶R )
      on conflict do nothing;
    return ¶R; end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
/* ### TAINT unsure how delete, then insert behaves under concurrency */
create function _MIRROR_._read_ch_and_update( ¶path text, ¶pch _MIRROR_.content_hash )
  returns text volatile language plpgsql as $$
  declare
    R       text  :=  _MIRROR_._ch_from_path( ¶path );
    ¶old_ch text;
  begin
    --......................................................................................................
    /* Retrieve previous CH, if any: */
    -- select into ¶old_ch ch from _MIRROR_.paths_and_chs where path = ¶path;
    ¶old_ch := ch from _MIRROR_.paths_and_chs where path = ¶path;
    --......................................................................................................
    /* Remove association between path and CH: */
    delete from _MIRROR_.paths_and_chs where path = ¶path;
    raise notice '98987 deleting entries for % (ch: %)', ¶path, R;
    --......................................................................................................
    /* Delete old CH and insert new CH: */
    delete from _MIRROR_.chs where ch = ¶old_ch and not exists (
      select 1 from _MIRROR_.paths_and_chs where ch = ¶old_ch );
    insert into _MIRROR_.chs ( ch ) values ( R ) on conflict do nothing;
    --......................................................................................................
    insert into _MIRROR_.paths_and_chs ( path, ch ) values ( ¶path, R );
      -- on conflict ( path, ch ) do update set ch = R;
    return R;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function _MIRROR_.cache_lines( ¶path text, ¶parameters json )
  returns void volatile language plpgsql as $$
  declare
    ¶parameters_txt   text                  :=  '';
    ¶fch              _MIRROR_.content_hash;
    ¶pch              _MIRROR_.content_hash;
  begin
    raise notice '44445 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>';
    if ¶parameters is not null then
      ¶parameters_txt :=  ¶parameters::text;
      end if;
    ¶pch  :=  _MIRROR_._ch_from_parameters( ¶parameters_txt );
    ¶fch  :=  _MIRROR_._read_ch_and_update( ¶path, ¶pch );
    raise notice '33382 >>>>>>>>>>>>>>>>>>> ¶pch %', ¶pch;
    if not exists ( select 1 from _MIRROR_.lines where fch = ¶fch and pch = ¶pch ) then
      insert into _MIRROR_.lines ( fch, pch, linenr, line )
        select ¶fch, ¶pch, r.linenr, r.line
        from FILELINEREADER.read_lines( ¶path, ¶parameters ) as r;
      end if;
    end;
  $$;

-- ---------------------------------------------------------------------------------------------------------
create function _MIRROR_.cache_lines( ¶path text )
  returns void volatile language sql as $$
  select _MIRROR_.cache_lines( ¶path, null ); $$;


/* ###################################################################################################### */


\ir './_mirror_.test.sql'


