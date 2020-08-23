


/* ###################################################################################################### */
\ir './start.test.sql'
\timing off

/* ====================================================================================================== */
begin;

\pset pager on
-- \timing on
-- \set ECHO queries


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists CATALOG cascade;
-- create schema CATALOG;
\ir '../070-catalog.sql'

-- select * from CATALOG.versions;
-- select * from CATALOG._tables_and_views
-- select
--     *
--   from CATALOG.catalog
--   where true
--     and ( schema not in ( 'public', 'catalog' ) )
--   order by
--     schema,
--     t,
--     name
--   ;

-- select distinct
--     schema
--   from CATALOG.catalog
--   where true
--     and ( schema not in ( 'public', 'catalog' ) )
--   order by
--     schema
--   ;

-- select * from CATALOG.catalog where schema ~ 'information_schema|pg_';
select * from CATALOG.catalog where name ~ 'raise|error|exception';

-- ---------------------------------------------------------------------------------------------------------
\quit



