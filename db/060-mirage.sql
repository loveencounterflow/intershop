
/*


——————————————————————————————————————————————————————————————
ooo        ooooo  o8o
`88.       .888'  `"'
 888b     d'888  oooo  oooo d8b  .oooo.    .oooooooo  .ooooo.
 8 Y88. .P  888  `888  `888""8P `P  )88b  888' `88b  d88' `88b
 8  `888'   888   888   888      .oP"888  888   888  888ooo888
 8    Y     888   888   888     d8(  888  `88bod8P'  888    .o
o8o        o888o o888o d888b    `Y888""8o `8oooooo.  `Y8bod8P'
————————————————————————————————————————— d"     YD ——————————
---        ----- ----- -----    --------- ---------  ---------
 -    -     ---   ---   ---     ---  ---  ---------  ---    --
 -  -----   ---   ---   ---      -------  ---   ---  ---------
 - ---- --  ---  ----  -------- --  ----  ---- ----  ---- ----
 ----     -----  ----  ---- ---  ------    ---------  -------
----       -----  ---
---        -----  ---

*/


-- ---------------------------------------------------------------------------------------------------------
create schema MIRAGE;


/* =========================================================================================================

ooooooooooooo
8'   888   `8
     888      oooo    ooo oo.ooooo.   .ooooo.   .oooo.o
     888       `88.  .8'   888' `88b d88' `88b d88(  "8
     888        `88..8'    888   888 888ooo888 `"Y88b.
     888         `888'     888   888 888    .o o.  )88b
    o888o         .8'      888bod8P' `Y8bod8P' 8""888P'
              .o..P'       888
              `Y8P'       o888o

thx to http://www.patorjk.com/software/taag/#p=display&f=Roman&t=Mirage

*/


-- ---------------------------------------------------------------------------------------------------------
/* Type for content hashes: */
create domain MIRAGE.content_hash as
  character( 17 ) check ( value ~ '^[0-9a-f]{17}$' );

comment on domain MIRAGE.content_hash is
  'type for content hashes (currently: leading 17 lower case hex digits of SHA1 hash digest)';

-- ---------------------------------------------------------------------------------------------------------
/* Type for content facets: */
create type MIRAGE.cacheline as (
  ch          text,
  mode        text,
  linenr      U.natural_number,
  include     boolean,
  line        text,
  fields      text[] );

-- ---------------------------------------------------------------------------------------------------------
create type MIRAGE._cachelinekernel as (
  linenr      U.natural_number,
  include     boolean,
  line        text,
  fields      text[] );


/* =========================================================================================================

oooooooooo.
`888'   `Y8b
 888     888  .oooo.    .oooo.o  .ooooo.   .oooo.o
 888oooo888' `P  )88b  d88(  "8 d88' `88b d88(  "8
 888    `88b  .oP"888  `"Y88b.  888ooo888 `"Y88b.
 888    .88P d8(  888  o.  )88b 888    .o o.  )88b
o888bood8P'  `Y888""8o 8""888P' `Y8bod8P' 8""888P'


*/


-- ---------------------------------------------------------------------------------------------------------
create table MIRAGE.chs   ( ch   text unique not null primary key );
create table MIRAGE.dsks  ( dsk  text unique not null primary key );
create table MIRAGE.paths ( path text unique not null primary key );

comment on table MIRAGE.chs   is 'registry of all content hashes (CHs)';
comment on table MIRAGE.dsks  is 'registry of all Data Source Keys (DSKs)';
comment on table MIRAGE.paths is 'registry of all file paths';

-- ---------------------------------------------------------------------------------------------------------
alter table MIRAGE.chs
  add constraint "CHs must consist of 17 lower case hexdigits"
  check ( ch::MIRAGE.content_hash = ch );


/* =========================================================================================================

ooo        ooooo                 .o8
`88.       .888'                "888
 888b     d'888   .ooooo.   .oooo888   .ooooo.   .oooo.o
 8 Y88. .P  888  d88' `88b d88' `888  d88' `88b d88(  "8
 8  `888'   888  888   888 888   888  888ooo888 `"Y88b.
 8    Y     888  888   888 888   888  888    .o o.  )88b
o8o        o888o `Y8bod8P' `Y8bod88P" `Y8bod8P' 8""888P'

*/


-- ---------------------------------------------------------------------------------------------------------
create table MIRAGE.mode_actors (
  actor     text    unique  not null primary key,
  category  text            not null,
  value     text );

comment on table MIRAGE.mode_actors is 'registry of skip and keep patterns';

-- ---------------------------------------------------------------------------------------------------------
create table MIRAGE.modes (
  mode        text  unique not null primary key,
  actors      text[] );

comment on table MIRAGE.modes is 'registry of all file paths and the CHs of the current file contents';

-- ---------------------------------------------------------------------------------------------------------
create view MIRAGE.modes_overview as (
  -- .......................................................................................................
  with mo as ( select
      mode              as mode,
      unnest( actors )  as actor
    from MIRAGE.modes ),
  -- .......................................................................................................
  mamo as ( select
      mo.mode                                 as mode,
      array[ mo.actor, ma.category, ma.value ]  as actor_definition
    from mo
    left join MIRAGE.mode_actors as ma on ( mo.actor = ma.actor ) )
  -- .......................................................................................................
  select distinct
      mode                                                            as mode,
      array_agg( actor_definition[ 1 ]  ) over ( partition by mode )  as actors,
      array_agg( actor_definition       ) over ( partition by mode )  as actor_definitions
    from mamo );

comment on view MIRAGE.modes_overview is 'overview giving MIRAGE modes, actors, and actor_definitions';

-- ---------------------------------------------------------------------------------------------------------
insert into MIRAGE.mode_actors
  ( actor,          category,     value                       ) values
  ( 'hashcomment',  'skip',       '^\s*#'                     ),
  ( 'blank',        'skip',       '^\s*$'                     ),
  ( 'ws',           'split',      '\s+'                       ),
  ( 'tab',          'split',      '\t'                        ),
  ( 'ptv3fields',   'match',      '^(\S+)\s+::(\S+)=\s+(.*)$' ),
  ( 'trimfields',   'fieldf',     null                        );

-- ---------------------------------------------------------------------------------------------------------
insert into MIRAGE.modes values
  ( 'plain',        null ),
  ( 'tsv',          array[ 'tab', 'trimfields'  ] ),
  ( 'cbtsv',        array[ 'blank', 'hashcomment', 'tab', 'trimfields' ] ),
  ( 'wsv',          array[ 'ws' ] ),
  ( 'cbwsv',        array[ 'blank', 'hashcomment', 'ws' ] ),
  ( 'ptv',          array[ 'blank', 'hashcomment', 'ptv3fields', 'trimfields' ] );


/* =========================================================================================================

ooooooooo.                             .o8
`888   `Y88.                          "888
 888   .d88'  .ooooo.   .oooo.    .oooo888   .ooooo.  oooo d8b  .oooo.o
 888ooo88P'  d88' `88b `P  )88b  d88' `888  d88' `88b `888""8P d88(  "8
 888`88b.    888ooo888  .oP"888  888   888  888ooo888  888     `"Y88b.
 888  `88b.  888    .o d8(  888  888   888  888    .o  888     o.  )88b
o888o  o888o `Y8bod8P' `Y888""8o `Y8bod88P" `Y8bod8P' d888b    8""888P'


*/


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function MIRAGE.read_lines( path_ text ) returns setof U.text_line
  stable language plpython3u as $$
  # plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  with open( path_, 'rb' ) as input:
    for line_idx, line in enumerate( input ):
      yield [ line_idx + 1, line.decode( 'utf-8' ).rstrip(), ]
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE._read_cachelinekernels( ¶path text, ¶mode text )
  returns setof MIRAGE._cachelinekernel stable language plpgsql as $$
  declare
    ¶actors     text[]        :=  actors from MIRAGE.modes where mode = ¶mode;
    ¶fields     text[];
    ¶fieldf     text;
    ¶fieldfs    text[];
    ¶do_fieldfs boolean;
    ¶idx        integer;
    ¶include    boolean;
    ¶matcher    text;
    ¶matchers   text[];
    ¶row        U.text_line;
    ¶skipper    text;
    ¶skippers   text[];
    ¶splitter   text;
    ¶splitters  text[];
    ¶unknown    text[];
  begin
    -- .....................................................................................................
    ¶unknown  := array_agg( given.actor ) from unnest( ¶actors ) as given( actor )
      where not exists ( select 1 from MIRAGE.mode_actors as known where known.actor = given.actor );
    -- .....................................................................................................
    if array_length( ¶unknown, 1 ) is distinct from null then
      raise exception 'MIRAGE #00921 unknown actors %', ¶unknown;
      end if;
    -- .....................................................................................................
    ¶skippers := array_agg( value ) from MIRAGE.mode_actors
      where array[ actor ] <@ ¶actors and category = 'skip';
    ¶skipper := array_to_string( ¶skippers, '|' );
    -- .....................................................................................................
    ¶fieldfs := array_agg( actor ) from MIRAGE.mode_actors
      where array[ actor ] <@ ¶actors and category = 'fieldf';
    ¶do_fieldfs := coalesce( array_length( ¶fieldfs, 1 ), 0 ) > 0;
    -- .....................................................................................................
    ¶splitters := array_agg( value ) from MIRAGE.mode_actors
      where array[ actor ] <@ ¶actors and category = 'split';
    -- .....................................................................................................
    case coalesce( array_length( ¶splitters, 1 ), 0 )
      when 0 then null;
      when 1 then ¶splitter := ¶splitters[ 1 ];
      else raise exception 'MIRAGE #00922 expected up to one splitter, got %', ¶splitters;
      end case;
    -- .....................................................................................................
    ¶matchers := array_agg( value ) from MIRAGE.mode_actors
      where array[ actor ] <@ ¶actors and category = 'match';
    -- .....................................................................................................
    case coalesce( array_length( ¶matchers, 1 ), 0 )
      when 0 then null;
      when 1 then ¶matcher := ¶matchers[ 1 ];
      else raise exception 'MIRAGE #00922 expected up to one matcher, got %', ¶matchers;
      end case;
    -- .....................................................................................................
    if ¶splitter is not null and ¶matcher is not null then
      raise exception 'MIRAGE #00923 expected either splitter or matcher, got % and %', ¶splitter, ¶matcher;
      end if;
    -- .....................................................................................................
    for ¶row in ( select linenr, line from MIRAGE.read_lines( ¶path ) ) loop
      if ¶skipper is not null then  ¶include := regexp_match( ¶row.line, ¶skipper ) is null;
      else                          ¶include := true; end if;
      if ¶include then
        if    ¶splitter  is not null then ¶fields :=  regexp_split_to_array(  ¶row.line, ¶splitter  );
        elsif ¶matcher   is not null then ¶fields :=  regexp_match(           ¶row.line, ¶matcher   );
        else                              ¶fields :=  null; end if;
        end if;
    -- .....................................................................................................
    if ¶do_fieldfs and ¶fields is not null then
      -- thx to https://stackoverflow.com/a/8586492/7568091
      -- ¶fields := array( select trim( both from unnest( ¶fields ) ) );
      -- the below solution takes 55.7s vs 64.5s for 285,699 lines (dt = 30s for 1e6 lines)
      for ¶idx in array_lower( ¶fields, 1 ) .. array_upper( ¶fields, 1 ) loop
        foreach ¶fieldf in array ¶fieldfs loop
          case ¶fieldf
            when 'trimfields' then ¶fields[ ¶idx ] := trim( both from ¶fields[ ¶idx ] );
            end case;
          end loop;
        end loop;
      end if;
    -- .....................................................................................................
      return next ( ¶row.linenr, ¶include, ¶row.line, ¶fields )::MIRAGE._cachelinekernel;
      end loop;
    -- .....................................................................................................
    end; $$;


/* =========================================================================================================

   oooo            o8o                  .
   `888            `"'                .o8
    888  .ooooo.  oooo  ooo. .oo.   .o888oo  .oooo.o
    888 d88' `88b `888  `888P"Y88b    888   d88(  "8
    888 888   888  888   888   888    888   `"Y88b.
    888 888   888  888   888   888    888 . o.  )88b
.o. 88P `Y8bod8P' o888o o888o o888o   "888" 8""888P'
`Y888P

*/


-- ---------------------------------------------------------------------------------------------------------
create table MIRAGE.paths_and_chs (
  path        text not null unique  references MIRAGE.paths ( path  ) on delete cascade,
  ch          text not null         references MIRAGE.chs   ( ch    ) on delete cascade,
  primary key ( path, ch ) );

comment on table MIRAGE.paths_and_chs is 'registry of all file paths and the CHs of the current file contents';

-- ---------------------------------------------------------------------------------------------------------
create table MIRAGE.dsks_and_pathmodes (
  dsk         text        not null references MIRAGE.dsks   ( dsk   ) on delete cascade,
  nr          integer     not null,
  path        text        not null references MIRAGE.paths  ( path  ),
  mode        text        not null references MIRAGE.modes  ( mode  ) on delete cascade,
  primary key ( dsk, nr ) );

comment on table MIRAGE.dsks_and_pathmodes is 'connects each DSK to a list of path/mode pairs';

-- ---------------------------------------------------------------------------------------------------------
/* Most of the time we will not want to use the same source file twice for a given data source key (DSK),
  so any repetitions of DSK + path is disallowed. Call `MIRAGE.enforce_unique_dsk_paths( false )` to remove
  that restriction. No attempt is made for more fine-grained control, as additional restrictions are
  probably better implemented in bespoke client-side DDL statements. */

create function MIRAGE.enforce_unique_dsk_paths( ¶enforce boolean )
  returns void volatile language plpgsql as $$
  begin
    if ¶enforce then
      alter table MIRAGE.dsks_and_pathmodes
        add constraint "enforce_unique_dsk_paths on dsks_and_pathmodes" unique ( dsk, path );
    else
      alter table MIRAGE.dsks_and_pathmodes
        drop constraint if exists "enforce_unique_dsk_paths on dsks_and_pathmodes";
    end if; end; $$;

do $$ begin perform MIRAGE.enforce_unique_dsk_paths( true ); end; $$;


/* =========================================================================================================

  .oooooo.                       oooo
 d8P'  `Y8b                      `888
888           .oooo.    .ooooo.   888 .oo.    .ooooo.
888          `P  )88b  d88' `"Y8  888P"Y88b  d88' `88b
888           .oP"888  888        888   888  888ooo888
`88b    ooo  d8(  888  888   .o8  888   888  888    .o
 `Y8bood8P'  `Y888""8o `Y8bod8P' o888o o888o `Y8bod8P'

*/

-- ---------------------------------------------------------------------------------------------------------
create table MIRAGE.cache of MIRAGE.cacheline (
  ch          not null references MIRAGE.chs    ( ch    ) on delete cascade,
  mode        not null references MIRAGE.modes  ( mode  ) on delete cascade,
  linenr      not null,
  include     not null,
  line        not null,
  primary key ( ch, mode, linenr ) );


/* =========================================================================================================

  .oooooo.   ooooo   ooooo
 d8P'  `Y8b  `888'   `888'
888           888     888   .oooo.o
888           888ooooo888  d88(  "8
888           888     888  `"Y88b.
`88b    ooo   888     888  o.  )88b
 `Y8bood8P'  o888o   o888o 8""888P'


*/


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function MIRAGE._ch_from_path_workhorse( ¶path text )
  returns text stable strict language plsh as $$#!/bin/bash
  sha1sum "$1" | cut --characters=-17
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
/* Just a wrapper for the workhorse function; being defined in plsh, it can't return UD types, just text */
create function MIRAGE._ch_from_path( ¶path text )
  returns MIRAGE.content_hash stable strict language sql as $$
  select MIRAGE._ch_from_path_workhorse( ¶path )::MIRAGE.content_hash; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.ch_from_text( text )
  returns MIRAGE.content_hash language sql immutable strict as $$
  select (
    substring(
      encode(
        _pgcrypto.digest( $1::bytea, 'sha1' ),
        'hex' )
      from 1 for 17 )
    )::MIRAGE.content_hash; $$;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function MIRAGE._ch_from_text_diagnostic( ¶text text ) returns MIRAGE.content_hash stable strict
  language plsh as $$#!/bin/bash
  printf "$1" | sha1sum | cut --characters=-17
  $$;
reset role;


/* =========================================================================================================

ooooo     ooo                  .o8                .
`888'     `8'                 "888              .o8
 888       8  oo.ooooo.   .oooo888   .oooo.   .o888oo  .ooooo.  oooo d8b  .oooo.o
 888       8   888' `88b d88' `888  `P  )88b    888   d88' `88b `888""8P d88(  "8
 888       8   888   888 888   888   .oP"888    888   888ooo888  888     `"Y88b.
 `88.    .8'   888   888 888   888  d8(  888    888 . 888    .o  888     o.  )88b
   `YbodP'     888bod8P' `Y8bod88P" `Y888""8o   "888" `Y8bod8P' d888b    8""888P'
               888
              o888o
*/


-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.freeze_cache() returns void volatile language sql as $$
  revoke  insert, update, delete, truncate on table MIRAGE.cache from public, current_user; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.thaw_cache() returns void volatile language sql as $$
  grant   insert, update, delete, truncate on table MIRAGE.cache to public, current_user; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.clear_cache() returns void volatile language plpgsql as $$
  begin
    perform MIRAGE.thaw_cache();
    truncate MIRAGE.cache;
    perform MIRAGE.freeze_cache();
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT use CH domain */
/* ### TAINT unsure how delete, then insert behaves under concurrency */
create function MIRAGE._read_ch_from_path_and_update( ¶path text )
  returns text volatile language plpgsql as $$
  declare
    ¶new_ch   MIRAGE.content_hash  :=  MIRAGE._ch_from_path( ¶path );
    ¶old_ch   MIRAGE.content_hash;
  begin
    --......................................................................................................
    /* Retrieve previous CH, if any: */
    ¶old_ch := ch from MIRAGE.paths_and_chs where path = ¶path;
    if ¶old_ch = ¶new_ch then return ¶old_ch; end if;
    --......................................................................................................
    /* Remove association between path and CH: */
    delete from MIRAGE.paths_and_chs where path = ¶path;
    --......................................................................................................
    /* Delete old CH and insert new CH: */
    perform MIRAGE.thaw_cache();
    delete from MIRAGE.chs where true
      and ( ch = ¶old_ch )
      and ( not exists ( select 1 from MIRAGE.paths_and_chs where ch = ¶old_ch ) );
    perform MIRAGE.freeze_cache();
    insert into MIRAGE.chs ( ch ) values ( ¶new_ch ) on conflict do nothing;
    --......................................................................................................
    insert into MIRAGE.paths_and_chs ( path, ch ) values ( ¶path, ¶new_ch );
    return ¶new_ch;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.refresh( ¶path text, ¶mode text )
  returns integer volatile language plpgsql as $$
  declare
    ¶ch             MIRAGE.content_hash;
    ¶affected_dsks  text;
    ¶affected_rows  bigint;
    ¶short_path     text;
  begin
    -- .....................................................................................................
    if ¶path is not distinct from null then raise exception 'MIRAGE #00931 path can not be null'; end if;
    if ¶mode is not distinct from null then raise exception 'MIRAGE #00932 mode can not be null'; end if;
    -- .....................................................................................................
    ¶ch :=  MIRAGE._read_ch_from_path_and_update( ¶path );
    -- .....................................................................................................
    if exists ( select 1 from MIRAGE.cache where ch = ¶ch and mode = ¶mode ) then return 0; end if;
    -- .....................................................................................................
    perform MIRAGE.thaw_cache();
    ¶short_path     :=  regexp_replace( ¶path, '^.*?([^/]+)$', '\1' );
    ¶affected_dsks  :=  array_to_string( array_agg( distinct dsk ), ', ' )
      from MIRAGE.dsks_and_pathmodes where path = ¶path and mode = ¶mode;
    -- .....................................................................................................
    if ¶affected_dsks is not distinct from null then
      raise exception 'MIRAGE #00930 unknown pathmode ( %, % )', ¶path, ¶mode;
      end if;
    -- .....................................................................................................
    perform log( 'MIRAGE #77384 caching:', ¶affected_dsks, format( '-> (%s)', ¶mode ), ¶short_path );
    -- .....................................................................................................
    insert into MIRAGE.cache ( ch, mode, linenr, include, line, fields )
      select ¶ch, ¶mode, r.linenr, r.include, r.line, r.fields
        from MIRAGE._read_cachelinekernels( ¶path, ¶mode ) as r;
    -- .....................................................................................................
    get diagnostics ¶affected_rows = row_count;
    perform log( format( 'MIRAGE #77384 read %s rows', to_char( ¶affected_rows, '999,999,999' ) ) );
    perform MIRAGE.freeze_cache();
    -- .....................................................................................................
    return 1; end; $$;

-- ---------------------------------------------------------------------------------------------------------
do $$ begin perform MIRAGE.freeze_cache(); end; $$;


/* =========================================================================================================

      .o.       ooooooooo.   ooooo
     .888.      `888   `Y88. `888'
    .8"888.      888   .d88'  888
   .8' `888.     888ooo88P'   888
  .88ooo8888.    888          888
 .8'     `888.   888          888
o88o     o8888o o888o        o888o


*/

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.delete_dsk( ¶dsk text ) returns integer volatile language sql as $$
  with d as ( delete from MIRAGE.dsks where dsk = ¶dsk returning * ) select count(*)::integer from d; $$;
  -- select sum(*)::integer from ( delete from MIRAGE.dsks where dsk = ¶dsk returning 1 ) as d; $$;
  -- delete from MIRAGE.dsks where dsk = ¶dsk returning count(*); $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE._max_dsk_pathmode_nr_from_dsk( ¶dsk text )
  returns setof integer volatile language plpgsql as $$
  declare
    ¶row MIRAGE.dsks_and_pathmodes%rowtype;
  begin
    for ¶row in select * from MIRAGE.dsks_and_pathmodes as s
      where s.dsk = ¶dsk order by s.nr desc limit 1 for update skip locked loop
        return next ¶row.nr;
        end loop;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.add_dsk_pathmode( ¶dsk text, ¶path text, ¶mode text )
  returns integer volatile language plpgsql as $$
  declare
    ¶next_nr  integer :=  MIRAGE._max_dsk_pathmode_nr_from_dsk( ¶dsk );
  begin
    ¶next_nr  :=  coalesce( ¶next_nr, 0 ) + 1;
    insert into MIRAGE.dsks  ( dsk  ) values ( ¶dsk  ) on conflict do nothing;
    insert into MIRAGE.paths ( path ) values ( ¶path ) on conflict do nothing;
    insert into MIRAGE.dsks_and_pathmodes ( dsk, nr, path, mode ) values ( ¶dsk, ¶next_nr, ¶path, ¶mode );
    return ¶next_nr; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.procure_dsk_pathmode( ¶dsk text, ¶path text, ¶mode text )
  returns integer volatile language plpgsql as $$
  begin
    if not exists ( select 1 from MIRAGE.dsks_and_pathmodes
      where ( dsk, path, mode ) = ( ¶dsk, ¶path, ¶mode ) ) then
      return MIRAGE.add_dsk_pathmode( ¶dsk, ¶path, ¶mode );
      end if;
    return 0; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create view MIRAGE.all_pathmodes as ( select distinct path, mode from MIRAGE.dsks_and_pathmodes );

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.refresh() returns integer volatile language sql as $$
  select sum( MIRAGE.refresh( path, mode ) )::integer from MIRAGE.all_pathmodes; $$;

-- ---------------------------------------------------------------------------------------------------------
create function MIRAGE.refresh( ¶dsk text ) returns integer volatile language plpgsql as $$
  begin
    if ¶dsk is not distinct from null then raise exception 'MIRAGE #00941 dsk can not be null'; end if;
    if not exists ( select 1 from MIRAGE.dsks where dsk = ¶dsk ) then
      raise exception 'MIRAGE #00942 unknown dsk %', ¶dsk;
      end if;
    return sum( MIRAGE.refresh( path, mode ) )::integer
      from MIRAGE.dsks_and_pathmodes where dsk = ¶dsk; end; $$;



/* =========================================================================================================

ooo        ooooo  o8o
`88.       .888'  `"'
 888b     d'888  oooo  oooo d8b oooo d8b  .ooooo.  oooo d8b
 8 Y88. .P  888  `888  `888""8P `888""8P d88' `88b `888""8P
 8  `888'   888   888   888      888     888   888  888
 8    Y     888   888   888      888     888   888  888
o8o        o888o o888o d888b    d888b    `Y8bod8P' d888b

*/

-- ---------------------------------------------------------------------------------------------------------
create view MIRAGE.mirror as ( select
    d.dsk       as dsk,
    d.nr        as nr,
    -- d.path      as path,
    -- c.ch        as ch,
    c.linenr    as linenr,
    c.mode      as mode,
    c.include   as include,
    c.line      as line,
    c.fields    as fields
  from MIRAGE.dsks_and_pathmodes  as d
  join MIRAGE.paths_and_chs         as p using ( path )
  join MIRAGE.cache                 as c using ( ch, mode )
  order by dsk, nr, linenr );



