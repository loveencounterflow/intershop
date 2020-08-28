


/* ###################################################################################################### */
\ir './start.test.sql'
\timing off

/* ====================================================================================================== */
begin;

\pset pager on
-- \timing on
-- \set ECHO queries


-- ---------------------------------------------------------------------------------------------------------
-- create schema CATALOG;
\ir '../070-catalog.sql'
\set filename 070-catalog.test.sql
\set signal :red
drop schema if exists T cascade; create schema T;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
create type   CATALOG.¶zzt as ( foo text, bar float );
create domain CATALOG.¶zzd as integer check ( value % 2 = 0 );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create function CATALOG.¶z( in x text )
  returns CATALOG.¶zzt immutable strict language plpgsql as $$ declare
  begin return ( 'x', 'y' )::CATALOG.¶zzt; end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
-- create function CATALOG.¶zzz( in x text, out y integer, out z integer )
create function CATALOG.¶zzz( x text, out y integer, out z integer )
  immutable strict language plpgsql as $$ declare
  begin
    y := 1;
    z := 2;
    return; end; $$;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
select * from CATALOG.parse_object_identifier( 'x.schema' ) union all
select * from CATALOG.parse_object_identifier( 'X.schema' ) union all
select * from CATALOG.parse_object_identifier( '"X.schema"' ) union all
select * from CATALOG.parse_object_identifier( 'X' ) union all
select * from CATALOG.parse_object_identifier( 'X."20"' ) union all
-- select * from CATALOG.parse_object_identifier( 'all' ) union all
-- select * from CATALOG.parse_object_identifier( 'select' ) union all
-- select * from CATALOG.parse_object_identifier( 'select.x' ) union all
-- select * from CATALOG.parse_object_identifier( 'x.select' ) union all
-- select * from CATALOG.parse_object_identifier( 'X.with space' ) union all
-- select * from CATALOG.parse_object_identifier( 'X.""' ) union all
-- select * from CATALOG.parse_object_identifier( 'X.SCHEMA.F' ) union all
select null, null where false;

-- create table select ( x integer );

-- select CATALOG.parse_object_identifier( word ) from CATALOG._must_quote;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
create table T.probes_and_matchers (
  id            bigint generated always as identity primary key,
  title         text,
  probe         text,
  matcher       text,
  result        text );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
-- insert into T.probes_and_matchers_1 ( title, probe, matcher ) values
--   ( 'get_product_1',             '{12,12}',         'helo'                      );
-- update T.probes_and_matchers_1 set result = LAZY.escape_text( probe ) where title = 'escape_text';

insert into T.probes_and_matchers ( title, probe_1, ok_matcher, error_matcher ) values
  ( 'parse_object_identifier', '{"x.schema"}', '(x,schema)', null );



-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
do $$
  declare
    ¶row    record;
    ¶ok     text;
    ¶result text;
  begin
    for ¶row in ( select * from T.probes_and_matchers where title = 'parse_object_identifier' ) loop
      ¶ok     :=  null;
      ¶error  :=  null;
      ¶ok     :=  CATALOG.parse_object_identifier( ¶row.probe_1 )::text;
      ¶result :=  ( ¶ok,)::text
      update T.probes_and_matchers set ok = ¶ok where id = ¶row.id;
      end loop;
    end; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 7 }———:reset
-- create view T.result_comparison as (
--   with v1 as ( select
--       *,
--       to_jsonb( array[ probe_1::integer, probe_2::integer ] ) as key
--     from T.probes_and_matchers )
--   select
--       v1.id,
--       v1.probe_1,
--       v1.probe_2,
--       r3.result,
--       r2.key,
--       r2.value,
--       r4.is_ok
--     from v1
--     left join LAZY.cache as r2 on r2.key = v1.key,
--     lateral ( select matcher::integer                                 )  as r3 ( result ),
--     lateral ( select coalesce( r3.result = r2.value::integer, false ) )  as r4 ( is_ok )
--     where v1.title = 'get_product_2'
--     order by r2.key );

-- select * from T.result_comparison;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
insert into INVARIANTS.tests select
    'CATALOG'                                                            as module,
    title                                                               as title,
    row( ok, ok_matcher )::text                                        as values,
    ( ok is null and ok_matcher is null ) or ( ok = ok_matcher )      as is_ok
  from T.probes_and_matchers as r1;

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 7 }———:reset
-- /* making sure that all tests get an entry in LAZY.cache: */
-- insert into INVARIANTS.tests select
--     'LAZY'                                                              as module,
--     'cache for ' || probe_1 || ', ' || probe_2                          as title,
--     row( result )::text                                                 as values,
--     is_ok                                                               as is_ok
--   from T.result_comparison as r1;


-- ---------------------------------------------------------------------------------------------------------
select * from T.probes_and_matchers order by id;


-- select * from INVARIANTS.tests;
select * from INVARIANTS.violations;
-- select count(*) from ( select * from INVARIANTS.violations limit 1 ) as x;
-- select count(*) from INVARIANTS.violations;
-- do $$ begin perform INVARIANTS.validate(); end; $$;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 14 }———:reset
\quit



