
-- ---------------------------------------------------------------------------------------------------------
-- \pset pager off
\ir '../010-trm.sql'

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _DEMO_CATALOG_ cascade;
create schema _DEMO_CATALOG_;

\ir './070-catalog2-10-recursive-report.sql'


\echo :orange'---==( 2 )==---':reset

create table _DEMO_CATALOG_.t_root (
  id serial primary key,
  value text );

create table _DEMO_CATALOG_.t_a_root (
  t_root_id integer unique not null references _DEMO_CATALOG_.t_root ( id ),
  value text );

create table _DEMO_CATALOG_.t_b_a_root (
  t_a_root_id integer unique not null references _DEMO_CATALOG_.t_a_root ( t_root_id ),
  value text );


create view  _DEMO_CATALOG_.v_b_a_root     as ( select * from _DEMO_CATALOG_.t_b_a_root );
create view  _DEMO_CATALOG_.v_v_ba_a_root  as ( select * from _DEMO_CATALOG_.v_b_a_root );
-- create view   _DEMO_CATALOG_.e as ( select * from _DEMO_CATALOG_.a join _DEMO_CATALOG_.b using ( value ) );


/* ###################################################################################################### */


/* thx to https://stackoverflow.com/a/11773226/7568091 */
create view CATALOG2._reference_implementation_dependencies as (
  SELECT
    dependent_ns.nspname            as dependent_schema,
    dependent_view.relname          as dependent_view,
    source_ns.nspname               as source_schema,
    source_table.relname            as source_table,
    pg_attribute.attname            as column_name
  FROM pg_depend
  JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
  JOIN pg_class as dependent_view ON pg_rewrite.ev_class = dependent_view.oid
  JOIN pg_class as source_table ON pg_depend.refobjid = source_table.oid
  JOIN pg_attribute ON pg_depend.refobjid = pg_attribute.attrelid
      AND pg_depend.refobjsubid = pg_attribute.attnum
  JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
  JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
  WHERE true
  -- and source_ns.nspname = 'CATALOG2'
  and ( dependent_ns.nspname not in ( 'information_schema', 'pg_catalog' ) )
  -- and source_ns.nspname = 'CATALOG2'::name
  -- AND source_table.relname = 'my_table'
  -- AND pg_attribute.attnum > 0
  -- AND pg_attribute.attname = 'my_column'
  ORDER BY
    dependent_schema,
    dependent_view,
    source_schema,
    source_table,
    column_name );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2._reference_implementation_dependencies_no_columns as (
  select distinct
      dependent_schema,
      dependent_view,
      source_schema,
      source_table
    from CATALOG2._reference_implementation_dependencies
  )
  ;

-- ---------------------------------------------------------------------------------------------------------
create table CATALOG2.serious_object_types (
  name        text unique not null primary key,
  is_serious  boolean not null );

-- ---------------------------------------------------------------------------------------------------------
insert into CATALOG2.serious_object_types values ( 'aggregate',                  false );
insert into CATALOG2.serious_object_types values ( 'default value',              false );
insert into CATALOG2.serious_object_types values ( 'domain constraint',          false );
insert into CATALOG2.serious_object_types values ( 'function of access method',  false );
insert into CATALOG2.serious_object_types values ( 'index',                      false );
insert into CATALOG2.serious_object_types values ( 'operator',                   false );
insert into CATALOG2.serious_object_types values ( 'operator class',             false );
insert into CATALOG2.serious_object_types values ( 'operator family',            false );
insert into CATALOG2.serious_object_types values ( 'operator of access method',  false );
insert into CATALOG2.serious_object_types values ( 'rule',                       false );
insert into CATALOG2.serious_object_types values ( 'sequence',                   false );
insert into CATALOG2.serious_object_types values ( 'table constraint',           false );
-- .........................................................................................................
insert into CATALOG2.serious_object_types values ( 'schema',                     true );
insert into CATALOG2.serious_object_types values ( 'table',                      true );
insert into CATALOG2.serious_object_types values ( 'type',                       true );
insert into CATALOG2.serious_object_types values ( 'view',                       true );
insert into CATALOG2.serious_object_types values ( 'materialized view',          true );
insert into CATALOG2.serious_object_types values ( 'language',                   true );
insert into CATALOG2.serious_object_types values ( 'function',                   true );
insert into CATALOG2.serious_object_types values ( 'extension',                  true );
insert into CATALOG2.serious_object_types values ( 'composite type',             true );

-- select distinct object_type from report.dependency order by object_type;
-- select * from CATALOG2._dt_excerpt_020;



-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2._dt_excerpt_010 as (
  select distinct
      dependency_chain[ array_length( dependency_chain, 1 ) - 1 ] as parent_objid,
      objid,
      objid::oid::regproc       as regproc,
      objid::oid::regoper       as regoper,
      objid::oid::regclass      as regclass,
      objid::oid::regtype       as regtype,
      objid::oid::regrole       as regrole,
      objid::oid::regnamespace  as regnamespace,
      objid::oid::name as xxx,
      level,
      lower( object_type ) as type,
      -- array_position( dependency_chain, objid ) != array_length( dependency_chain, 1 ),
      object_identity
  from report.dependency
  -- where object_identity ~ 'mirage'
  -- where object_identity ~ 'CATALOG2'
  -- order by
  --   object_type,
  --   object_identity
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2._dt_excerpt_020 as (
  select * from CATALOG2._dt_excerpt_010 where parent_objid is distinct from null
  );



/* ###################################################################################################### */
-- select * from CATALOG2._reference_implementation_dependencies;
-- select * from CATALOG2._reference_implementation_dependencies_no_columns;
\set ECHO queries
select * from CATALOG2.osn_catalog_with_oids limit 15;
\set ECHO none
\quit

select * from CATALOG2._reference_implementation_dependencies            where dependent_schema = 'CATALOG2';
select * from CATALOG2._reference_implementation_dependencies_no_columns where dependent_schema = 'CATALOG2';

-- select report.dependency_tree('t_a_root');
-- select report.dependency_tree('^mirage$');
select report.dependency_tree('mirror');
-- select report.dependency_tree('^cache$');
select * from CATALOG2._dt_excerpt_020;


\quit

select distinct
    pg_typeof( isa          ) as type_of_isa,
    pg_typeof( owner_oid    ) as type_of_owner_oid,
    pg_typeof( schema_oid   ) as type_of_schema_oid,
    pg_typeof( self_oid     ) as type_of_self_oid,
    pg_typeof( owner_name   ) as type_of_owner_name,
    pg_typeof( schema_name  ) as type_of_schema_name,
    pg_typeof( self_name    ) as type_of_self_name
  from CATALOG2.schemas;
select distinct
    pg_typeof( isa          ) as type_of_isa,
    pg_typeof( owner_oid    ) as type_of_owner_oid,
    pg_typeof( schema_oid   ) as type_of_schema_oid,
    pg_typeof( self_oid     ) as type_of_self_oid,
    pg_typeof( owner_name   ) as type_of_owner_name,
    pg_typeof( schema_name  ) as type_of_schema_name,
    pg_typeof( self_name    ) as type_of_self_name
  from CATALOG2.relations;
