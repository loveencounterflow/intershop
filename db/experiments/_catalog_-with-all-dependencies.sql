
-- ---------------------------------------------------------------------------------------------------------
-- \pset pager off
\ir '../010-trm.sql'

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _CATALOG_ cascade;
create schema _CATALOG_;

\ir '_catalog_-this-is-huge.sql'


\echo :orange'---==( 2 )==---':reset

create table _CATALOG_.t_root (
  id serial primary key,
  value text );

create table _CATALOG_.t_a_root (
  t_root_id integer unique not null references _CATALOG_.t_root ( id ),
  value text );

create table _CATALOG_.t_b_a_root (
  t_a_root_id integer unique not null references _CATALOG_.t_a_root ( t_root_id ),
  value text );


create view  _CATALOG_.v_b_a_root     as ( select * from _CATALOG_.t_b_a_root );
create view  _CATALOG_.v_v_ba_a_root  as ( select * from _CATALOG_.v_b_a_root );
-- create view   _CATALOG_.e as ( select * from _CATALOG_.a join _CATALOG_.b using ( value ) );


/* ###################################################################################################### */


-- ---------------------------------------------------------------------------------------------------------
/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
/* thx to https://stackoverflow.com/a/46594226/7568091 */

create view _CATALOG_.dependencies as (
  WITH RECURSIVE view_deps AS (
  SELECT DISTINCT dependent_ns.nspname as dependent_schema
  , dependent_view.relname as dependent_view
  , source_ns.nspname as source_schema
  , source_table.relname as source_table
  FROM pg_depend
  JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
  JOIN pg_class as dependent_view ON pg_rewrite.ev_class = dependent_view.oid
  JOIN pg_class as source_table ON pg_depend.refobjid = source_table.oid
  JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
  JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
  WHERE NOT (dependent_ns.nspname = source_ns.nspname AND dependent_view.relname = source_table.relname)
  UNION
  SELECT DISTINCT dependent_ns.nspname as dependent_schema
  , dependent_view.relname as dependent_view
  , source_ns.nspname as source_schema
  , source_table.relname as source_table
  FROM pg_depend
  JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
  JOIN pg_class as dependent_view ON pg_rewrite.ev_class = dependent_view.oid
  JOIN pg_class as source_table ON pg_depend.refobjid = source_table.oid
  JOIN pg_namespace dependent_ns ON dependent_ns.oid = dependent_view.relnamespace
  JOIN pg_namespace source_ns ON source_ns.oid = source_table.relnamespace
  INNER JOIN view_deps vd
      ON vd.dependent_schema = source_ns.nspname
      AND vd.dependent_view = source_table.relname
      AND NOT (dependent_ns.nspname = vd.dependent_schema AND dependent_view.relname = vd.dependent_view)
  )

  SELECT *
  FROM view_deps
  where true
    and ( dependent_schema not in ( 'information_schema', 'pg_catalog' ) )
  ORDER BY
    dependent_schema,
    dependent_view,
    source_schema,
    source_table,
    true );

/* thx to https://stackoverflow.com/a/11773226/7568091 */
create view _CATALOG_.dependencies_shorter_version as (
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
  -- and source_ns.nspname = '_catalog_'
  and ( dependent_ns.nspname not in ( 'information_schema', 'pg_catalog' ) )
  -- and source_ns.nspname = '_CATALOG_'::name
  -- AND source_table.relname = 'my_table'
  -- AND pg_attribute.attnum > 0
  -- AND pg_attribute.attname = 'my_column'
  ORDER BY
    dependent_schema,
    dependent_view,
    source_schema,
    source_table,
    column_name );

create view _CATALOG_.dependencies_shorter_version_no_columns as (
  select distinct
      dependent_schema,
      dependent_view,
      source_schema,
      source_table
    from _CATALOG_.dependencies_shorter_version
  )
  ;

/* ###################################################################################################### */
-- select * from _CATALOG_.dependencies;
-- select * from _CATALOG_.dependencies_shorter_version;
-- select * from _CATALOG_.dependencies_shorter_version_no_columns;

select * from _CATALOG_.dependencies                            where dependent_schema = '_catalog_';
select * from _CATALOG_.dependencies_shorter_version            where dependent_schema = '_catalog_';
select * from _CATALOG_.dependencies_shorter_version_no_columns where dependent_schema = '_catalog_';

-- select report.dependency_tree('t_a_root');
-- select report.dependency_tree('^mirage$');
select report.dependency_tree('mirror');
-- select report.dependency_tree('^cache$');

create view _CATALOG_._dt_excerpt_010 as (
  select distinct
      dependency_chain[ array_length( dependency_chain, 1 ) - 1 ] as parent_objid,
      objid,
      level,
      object_type,
      -- array_position( dependency_chain, objid ) != array_length( dependency_chain, 1 ),
      object_identity
  from report.dependency
  -- where object_identity ~ 'mirage'
  order by
    object_type,
    object_identity
  );

create view _CATALOG_._dt_excerpt_020 as (
  select * from _CATALOG_._dt_excerpt_010 where parent_objid is distinct from null
  );

create table _CATALOG_.serious_object_types (
  name        text unique not null primary key,
  is_serious  boolean not null );

insert into _CATALOG_.serious_object_types values ( 'AGGREGATE',                  false );
insert into _CATALOG_.serious_object_types values ( 'DEFAULT VALUE',              false );
insert into _CATALOG_.serious_object_types values ( 'DOMAIN CONSTRAINT',          false );
insert into _CATALOG_.serious_object_types values ( 'FUNCTION OF ACCESS METHOD',  false );
insert into _CATALOG_.serious_object_types values ( 'INDEX',                      false );
insert into _CATALOG_.serious_object_types values ( 'OPERATOR',                   false );
insert into _CATALOG_.serious_object_types values ( 'OPERATOR CLASS',             false );
insert into _CATALOG_.serious_object_types values ( 'OPERATOR FAMILY',            false );
insert into _CATALOG_.serious_object_types values ( 'OPERATOR OF ACCESS METHOD',  false );
insert into _CATALOG_.serious_object_types values ( 'RULE',                       false );
insert into _CATALOG_.serious_object_types values ( 'SEQUENCE',                   false );
insert into _CATALOG_.serious_object_types values ( 'TABLE CONSTRAINT',           false );
-- .........................................................................................................
insert into _CATALOG_.serious_object_types values ( 'SCHEMA',                     true );
insert into _CATALOG_.serious_object_types values ( 'TABLE',                      true );
insert into _CATALOG_.serious_object_types values ( 'TYPE',                       true );
insert into _CATALOG_.serious_object_types values ( 'VIEW',                       true );
insert into _CATALOG_.serious_object_types values ( 'MATERIALIZED VIEW',          true );
insert into _CATALOG_.serious_object_types values ( 'LANGUAGE',                   true );
insert into _CATALOG_.serious_object_types values ( 'FUNCTION',                   true );
insert into _CATALOG_.serious_object_types values ( 'EXTENSION',                  true );
insert into _CATALOG_.serious_object_types values ( 'COMPOSITE TYPE',             true );

select distinct object_type from report.dependency order by object_type;
-- select * from _CATALOG_._dt_excerpt_020;

