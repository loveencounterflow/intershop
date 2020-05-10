

-- \set ECHO queries

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename datamill/000-first.sql
\set signal :green

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
begin transaction;
drop schema if exists DEMO cascade;
create schema DEMO;



-- =========================================================================================================
-- DOMAINS
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
-- ### TAINT use intershop.ptv variables to make configurable?
create domain DEMO.positive_integer as integer  check ( value > 0                   );
create domain DEMO.nonempty_text    as text     check ( value ~ '.+'                );
-- create domain DEMO.absolute_path    as text     check ( DEMO.test_absolute_path( value ) );
-- create domain DEMO.topic            as text     check ( DEMO.test_topic( value ) );
-- create domain DEMO.focus            as text     check ( DEMO.test_focus( value ) );

-- comment on domain DEMO.absolute_path is 'Data type for FlowMatic paths (qualified names); must be either a
-- slash (for the root element) or else start with a slash, followed by at least one character other than a
-- slash, not contain any slash directly followed by another slash, and not end in a slash.';


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
--     partid    bigint                  generated by default as identity primary key,

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create table DEMO.datoms (
  -- doc         integer     not null references
  -- dsk
  -- dsnr
  vnr         integer[]   not null,
  key         text        not null,
  atr         jsonb,      -- consider to use hstore
  stamped     boolean     not null default false,
  primary key ( vnr ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create function DEMO.on_before_update_datoms() returns trigger language plpgsql as $$ begin
  raise sqlstate 'IMM04' using message = format( 'illegal to update record %s', old ); end; $$;

create trigger on_before_update_datoms before update on DEMO.datoms
  for each row when ( old is distinct from new and (
    ( old.stamped = true and new.stamped = false ) or IMMUTABLE.record_has_changed( old, new ) ) )
  execute procedure DEMO.on_before_update_datoms();


-- #########################################################################################################

-- ---------------------------------------------------------------------------------------------------------
create function DEMO.expand_vnr_for_sorting( ¶vnr float8[] )
  returns float8[] immutable parallel safe language plpgsql as $$
  declare
    ¶max_length integer := 20;
    ¶length     integer := coalesce( array_length( ¶vnr, 1 ), 0 );
  begin
    if ¶length > ¶max_length then
      raise sqlstate 'VNR72' using message = format(
        'vnr must not be longer than %s elements, got %s', ¶max_length, ¶vnr );
      end if;
    return array_cat( ¶vnr, array_fill( 0::float8, array[ ¶max_length - ¶length ] ) );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function DEMO.expand_vnr_for_sorting( ¶vnr integer[] )
  returns integer[] immutable parallel safe language sql as $$
  select DEMO.expand_vnr_for_sorting( ¶vnr::float8[] )::integer[]; $$;

-- ---------------------------------------------------------------------------------------------------------
create function DEMO.add_final_zero( ¶vnr float8[] )
  returns float8[] immutable parallel safe language plpgsql as $$
  begin
    return array_append( ¶vnr, 0::float8 );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function DEMO.add_final_zero( ¶vnr integer[] )
  returns integer[] immutable parallel safe language sql as $$
  select DEMO.add_final_zero( ¶vnr::float8[] )::integer[]; $$;

-- ---------------------------------------------------------------------------------------------------------
create table DEMO.vnr_float8 (
  nr        integer generated by default as identity primary key,
  vnr       float8[] not null,
  vnr0      float8[] generated always as ( DEMO.add_final_zero( vnr ) ) stored,
  vnr_long  float8[] generated always as ( DEMO.expand_vnr_for_sorting( vnr ) ) stored
  );

create table DEMO.vnr_integer (
  nr        integer generated by default as identity primary key,
  vnr       integer[] not null,
  vnr0      integer[] generated always as ( DEMO.add_final_zero( vnr ) ) stored,
  vnr_long  integer[] generated always as ( DEMO.expand_vnr_for_sorting( vnr ) ) stored
  );

insert into DEMO.vnr_float8 ( vnr ) values
  ( array[ 2, '-infinity'::float8       ] ),
  ( array[ 2, -9007199254740991         ] ), -- JS `Number.MIN_SAFE_INTEGER`
  ( array[ 2, -2147483648               ] ), -- PG min `integer`
  ( array[ 2, -9999999                  ] ),
  ( array[ 2, 0                         ] ),
  ( array[ 2, 5e-324                    ] ), -- JS `Number.MIN_VALUE`
  ( array[ 2, 1                         ] ),
  ( array[ 2, 1, 1, 1, 1, -1            ] ),
  ( array[ 2, 1, 1, 1, 1                ] ),
  ( array[ 2, 1, 1, 1, 1, +1            ] ),
  ( array[ 2, 10, -1                    ] ),
  ( array[ 2, 10                        ] ),
  ( array[ 2, 10, 0                     ] ),
  ( array[ 2, 10, 1                     ] ),
  ( array[ 2, 100                       ] ),
  ( array[ 2, 1000                      ] ),
  ( array[ 2, +9999999                  ] ),
  ( array[ 2, +2147483648               ] ), -- PG max `integer`
  ( array[ 2, 9007199254740991          ] ), -- JS `Number.MAX_SAFE_INTEGER`
  ( array[ 2, 1.7976931348623157e+308   ] ), -- JS `Number.MAX_VALUE`
  ( array[ 2, '+infinity'::float8, -1   ] ),
  ( array[ 2, '+infinity'::float8       ] ),
  ( array[ 2, '+infinity'::float8, +1   ] );

insert into DEMO.vnr_integer ( vnr ) values
  ( array[ 2, -2147483648         ] ),
  ( array[ 2, 1                   ] ),
  ( array[ 2, 1, 1, 1, 1, -1      ] ),
  ( array[ 2, 1, 1, 1, 1          ] ),
  ( array[ 2, 1, 1, 1, 1, +1      ] ),
  ( array[ 2, 10, -1              ] ),
  ( array[ 2, 10                  ] ),
  ( array[ 2, 10, 0               ] ),
  ( array[ 2, 10, 1               ] ),
  ( array[ 2, 100                 ] ),
  ( array[ 2, 1000                ] ),
  ( array[ 2, +2147483647         ] );

-- create unique index on DEMO.vnr_integer using btree ( DEMO.add_final_zero( vnr ) );
create unique index on DEMO.vnr_integer ( DEMO.add_final_zero( vnr ) );

select * from DEMO.vnr_float8 order by vnr;
-- select * from DEMO.vnr_float8 order by vnr_long;
select * from DEMO.vnr_float8 order by vnr0;
select * from DEMO.vnr_float8 order by DEMO.add_final_zero( vnr );
explain analyze select * from DEMO.vnr_float8 order by DEMO.add_final_zero( vnr );
-- select * from DEMO.vnr_integer order by vnr0;
-- select * from DEMO.vnr_integer order by vnr_long;
-- select '+infinity'::float8, '-infinity'::float8;


/* ###################################################################################################### */
\echo :red ———{ :filename 15 }———:reset
\quit




-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
select * from CATALOG.catalog where schema = 'demo';




