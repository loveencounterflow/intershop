
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

SELECT report.dependency_tree('');

