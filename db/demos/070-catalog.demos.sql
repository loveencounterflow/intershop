


/* ###################################################################################################### */
-- \ir './start.test.sql'
\timing off
begin transaction;


/* ====================================================================================================== */
begin;

\pset pager on
-- \timing on
-- \set ECHO queries


-- ---------------------------------------------------------------------------------------------------------
-- create schema CATALOG;
\ir '../_trm.sql'
\ir '../070-catalog.sql'
\set filename 070-catalog.demos.sql
\set signal :red

-- ---------------------------------------------------------------------------------------------------------
/* ### NOTE the intention of this function is to give a more saner name to PG's *_is_visible', which in fact
means 'is on the search path' and therefore 'can be used without a qualifying schema'. As it stands
we still would have to implement type lookup to know which underlying function to call.

create function CATALOG.usable_without_schema( oid ) returns boolean stable language sql as $$
  select not pg_catalog.pg_type_is_visible( $1 ); $$;
*/




-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset

-- select * from CATALOG._must_quote;


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


-- thx to https://stackoverflow.com/a/16349665/7568091
create view CATALOG.types_as_suggested_on_stackoverflow as ( select
    r2.nspname                                        as schema,
    -- pg_catalog.format_type( r1.oid, null )            as namexxxxx,
    r1.typname                                        as name,
    pg_catalog.obj_description( r1.oid, 'pg_type' )   as remarks
  from pg_catalog.pg_type           as r1
  left join pg_catalog.pg_namespace as r2 on r2.oid = r1.typnamespace
  where true
    and (
      ( r1.typrelid = 0 ) or
      ( select c.relkind = 'c' from pg_catalog.pg_class c where c.oid = r1.typrelid ) )
    and ( not exists
      ( select 1 from pg_catalog.pg_type el
        where ( el.oid = r1.typelem ) and ( el.typarray = r1.oid ) ) )
  order by 1, 2 );




-- select * from CATALOG._functions_and_return_types where schema = 'catalog' order by name;
-- select * from pg_proc order by proname;
-- select * from CATALOG._function_argument_types;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
create view CATALOG.schema_names as ( select
    'pg_namespace'    as source,
    'schema'          as type,
    oid               as oid,
    nspname           as schema,
    upper( nspname )  as ucschema,
    null              as name,
    upper( nspname )  as fqname
  from PG_CATALOG.pg_namespace );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function CATALOG._schema_from_oid( oid )
  returns text stable strict language sql as $$ select
  nspname::text from pg_namespace where oid = $1; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create function CATALOG._ucschema_from_oid( oid )
  returns text stable strict language sql as $$ select
  upper( nspname::text ) from pg_namespace where oid = $1; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create function CATALOG._get_fqname( ¶schema text, ¶name text )
  returns text immutable strict language sql as $$ select
  case
    when ¶schema ~* '^(public|pg_catalog)$' then ¶name
    else format( '%s.%s', ¶schema, ¶name ) end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create view CATALOG.function_names as ( select
    'pg_proc'         as source,
    'function'        as type,
    r1.oid            as oid,
    r2.schema         as schema,
    r3.ucschema       as ucschema,
    r1.proname        as name,
    r4.fqname         as fqname
  from PG_CATALOG.pg_proc                                 as r1,
  lateral CATALOG._schema_from_oid(   r1.pronamespace )   as r2 ( schema ),
  lateral CATALOG._ucschema_from_oid( r1.pronamespace )   as r3 ( ucschema ),
  lateral CATALOG._get_fqname( r3.ucschema, r1.proname )      as r4 ( fqname ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create view CATALOG.view_names as ( select
    'pg_views'        as source,
    'view'            as type,
    r5.oid            as oid,
    r1.schemaname     as schema,
    r3.ucschema       as ucschema,
    r1.viewname       as name,
    r4.fqname         as fqname
  from PG_CATALOG.pg_views                                as r1,
  lateral upper( r1.schemaname )                          as r3 ( ucschema ),
  lateral CATALOG._get_fqname( r3.ucschema, r1.viewname )     as r4 ( fqname ),
  lateral ( select r4.fqname::regclass::oid )             as r5 ( oid ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
create view CATALOG.matview_names as ( select
    'pg_matviews'     as source,
    'mview'           as type,
    r5.oid            as oid,
    r1.schemaname     as schema,
    r3.ucschema       as ucschema,
    r1.matviewname    as name,
    r4.fqname         as fqname
  from PG_CATALOG.pg_matviews                             as r1,
  lateral upper( r1.schemaname )                          as r3 ( ucschema ),
  lateral CATALOG._get_fqname( r3.ucschema, r1.matviewname )  as r4 ( fqname ),
  lateral ( select r4.fqname::regclass::oid )             as r5 ( oid ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
create view CATALOG.table_names as ( select
    'pg_tables'       as source,
    'table'           as type,
    r5.oid            as oid,
    r1.schemaname     as schema,
    r3.ucschema       as ucschema,
    r1.tablename      as name,
    r4.fqname         as fqname
  from PG_CATALOG.pg_tables                               as r1,
  lateral upper( r1.schemaname )                          as r3 ( ucschema ),
  lateral CATALOG._get_fqname( r3.ucschema, r1.tablename )    as r4 ( fqname ),
  lateral ( select r4.fqname::regclass::oid )             as r5 ( oid ) );


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create view CATALOG.type_names as ( select
    'pg_type'         as source,
    'type'            as type,
    r1.oid            as oid,
    r2.schema         as schema,
    r3.ucschema       as ucschema,
    r1.typname        as name,
    r4.fqname         as fqname
  from PG_CATALOG.pg_type                                 as r1,
  lateral CATALOG._schema_from_oid(   r1.typnamespace )   as r2 ( schema ),
  lateral CATALOG._ucschema_from_oid( r1.typnamespace )   as r3 ( ucschema ),
  lateral CATALOG._get_fqname( r3.ucschema, r1.typname )      as r4 ( fqname ) );

-- select * from PG_CATALOG.pg_type;
-- \quit

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
create view CATALOG.names as (
            select * from CATALOG.schema_names
  union all select * from CATALOG.function_names
  union all select * from CATALOG.view_names
  union all select * from CATALOG.matview_names
  union all select * from CATALOG.table_names
  union all select * from CATALOG.type_names
  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create function CATALOG.get_fqname( ¶type text, ¶oid oid ) returns text stable strict language sql as $$ select
  fqname from CATALOG.names where type = ¶type and oid = ¶oid; $$;

-- select * from CATALOG.type_names;

-- select * from pg_proc;
-- select * from pg_tables;

/*

see https://www.postgresql.org/docs/current/internals.html
see https://www.postgresql.org/docs/current/catalogs.html

??? pg_catalog
??? pg_user
??? pg_get_keywords
??? pg_depend
??? pg_class

pg_matviews
pg_type
pg_language
*/

-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 9 }———:reset
-- create view CATALOG.functions_upcoming as ( select
--       'type'::text                              as t,
--       pn.nspname                                as schema,
--       pt.typname                                as name,
--       pg_catalog.obj_description( pt.oid, 'pg_type' )   as remarks
--     from pg_catalog.pg_type                           as pt
--     left join pg_namespace                           as pn on ( pt.typnamespace = pn.oid )
--     -- where pn.nspname != 'pg_catalog' -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--     );


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 12 }———:reset
-- ### TAINT this view contains return types, merge with _functions_with_defs_all
create view CATALOG._functions_and_return_types as ( select
    pn.nspname                    as schema,
    pp.proname                    as name,
    pt.typname                    as return_type,
    r4.return_fqtype              as return_fqtype,
    pp.proargnames                as argument_names,
    pp.proallargtypes             as argument_type_oids,
    pp.proargmodes                as argument_modes,
    pp.prorettype                 as return_type_oid,
    pp.pronargs                   as argument_count
  from pg_proc as pp
  inner join pg_namespace as pn on ( pp.pronamespace = pn.oid )
  inner join pg_type      as pt on ( pp.prorettype   = pt.oid ),
  lateral CATALOG.get_fqname( 'type', pp.prorettype ) as r4 ( return_fqtype )
  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 13 }———:reset
create view CATALOG._function_argument_types as ( select
    pp.pronamespace                 as schema_oid,
    lower( r5.ucschema )            as schema,
    r5.ucschema                     as ucschema,
    pp.proname                      as name,
    r1.nr                           as nr,
    -- r1.argument_type_oid            as argument_type_oid,
    pp.proargmodes[ nr ]            as mode,
    r4.fqtype                       as fqtype
  from pg_proc                                                  as pp,
  lateral unnest( pp.proallargtypes ) with ordinality           as r1 ( argument_type_oid, nr ),
  lateral CATALOG.get_fqname( 'type',   r1.argument_type_oid  ) as r4 ( fqtype ),
  lateral CATALOG.get_fqname( 'schema', pp.pronamespace       ) as r5 ( ucschema )
  -- inner join pg_type                                  as pt on ( r1.argument_type_oid = pt.oid )
    )
    ;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 14 }———:reset
select * from CATALOG._functions_and_return_types where schema = 'catalog';
select * from CATALOG._function_argument_types where schema = 'catalog';


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 14 }———:reset
\quit



