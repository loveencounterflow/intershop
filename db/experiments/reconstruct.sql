

-- ---------------------------------------------------------------------------------------------------------
\pset pager on
\ir '../010-trm.sql'
\echo :cyan'——————————————————————— demo-filelinereader.sql ———————————————————————':reset

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists RECONSTRUCT cascade;
create schema RECONSTRUCT;

-- ---------------------------------------------------------------------------------------------------------
create table RECONSTRUCT.to_be_dropped ( pattern text unique not null );

insert into RECONSTRUCT.to_be_dropped values ( 'U.*' );
insert into RECONSTRUCT.to_be_dropped values ( 'FILELINEREADER.*' );
-- insert into RECONSTRUCT.to_be_dropped values ( 'RECONSTRUCT.*' );

-- -- ---------------------------------------------------------------------------------------------------------
-- create view RECONSTRUCT._schemas_to_be_dropped_on_reconstruct as ( select
--   schemaname as schema from pg_tables where tablename = '_drop_on_reconstruct' );

-- -- ---------------------------------------------------------------------------------------------------------
-- create view RECONSTRUCT.drop_statements as ( select
--     schema                                                      as schema,
--     format( $$ drop schema if exists %I cascade; $$, schema )   as statement
--   from RECONSTRUCT._schemas_to_be_dropped_on_reconstruct );



-- ---------------------------------------------------------------------------------------------------------
create function RECONSTRUCT._cast_schemaname( ¶schema text )
  returns regnamespace stable strict language plpgsql as $$
  begin
    return ¶schema::regnamespace;
        raise notice '22982 statement: %', ¶statement;
    exception
      when /* 3F000 */ invalid_schema_name then
        raise notice 'unknown schema %, skipping - [(%) %]', ¶schema, sqlstate, sqlerrm;
        return null;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function RECONSTRUCT.drop_schemas() returns void volatile language plpgsql as $$
  declare
    ¶row          record;
    ¶schema       text;
    ¶schema_reg   regnamespace;
    ¶statement    text;
  begin
    for ¶row in ( select * from RECONSTRUCT.to_be_dropped ) loop
      raise notice '22981 pattern: %', ¶row.pattern;
      case when ¶row.pattern ~ '\.\*$' then
        ¶schema     :=  trim( trailing from ¶row.pattern, '.*' );
        ¶schema_reg :=  RECONSTRUCT._cast_schemaname( ¶schema );
        if ¶schema_reg is distinct from null then
          ¶statement  := format( $x$ drop schema if exists %I cascade; $x$, ¶schema::regnamespace );
          raise notice '22982 schema: %', ¶schema::regnamespace;
          raise notice '22982 statement: %', ¶statement;
          execute ¶statement;
          end if;
      else
        raise exception 'not a valid pattern: %', ¶row.pattern;
        end case;
      end loop;
    end; $$;
-- ---------------------------------------------------------------------------------------------------------
-- select * from RECONSTRUCT.drop_statements;
do $$ begin perform RECONSTRUCT.drop_schemas(); end; $$;

\quit

-- select
--     *
--   from
--     information_schema.schemata
--   where true
--     and schema_owner = 'intershop'
--     -- and schema_name !~ '^(_|pg_)'
--     ;

select * from CATALOG.catalog
  where true
    -- and name = 'keep_on_reconstruct'
    and name = '_drop_on_reconstruct'
    -- and t = 'rt'
  -- where schema = 'RECONSTRUCT'
  ;

select * from CATALOG.dependencies;

-- select RECONSTRUCT.count_text_filelines( :'path' );
\timing on

-- ---------------------------------------------------------------------------------------------------------
\echo :orange'---==( plpython3u )==---':reset
create materialized view RECONSTRUCT.filelines_via_plpython3u as (
  select
      paths.path                as path,
      lines.linenr              as linenr,
      lines.line                as line
    from RECONSTRUCT.paths as paths,
    lateral FILELINEREADER.read_lines( '/home/flow/io/mingkwai-rack/jzrds' || '/' || paths.path ) as lines
      );

-- ---------------------------------------------------------------------------------------------------------
select * from RECONSTRUCT.filelines_via_plpython3u;
-- select * from RECONSTRUCT.filelines_via_plpython3u order by path, linenr;
select count(*) from RECONSTRUCT.filelines_via_plpython3u;


\quit

set role dba;
reset role;

