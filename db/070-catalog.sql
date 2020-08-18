

/*

 .d8888b.        d8888 88888888888    d8888  888      .d88888b.   .d8888b.
d88P  Y88b      d88888     888       d88888  888     d88P" "Y88b d88P  Y88b
888    888     d88P888     888      d88P888  888     888     888 888    888
888           d88P 888     888     d88P 888  888     888     888 888
888          d88P  888     888    d88P  888  888     888     888 888  88888
888    888  d88P   888     888   d88P   888  888     888     888 888    888
Y88b  d88P d8888888888     888  d8888888888  888     Y88b. .d88P Y88b  d88P
 "Y8888P" d88P     888     888 d88P     888  88888888 "Y88888P"   "Y8888P88

*/


-- ---------------------------------------------------------------------------------------------------------
create schema CATALOG;

-- ---------------------------------------------------------------------------------------------------------
create function CATALOG.count_tuples( schema text, name text )
  returns integer
  language plpgsql
  as $$
    declare
      R integer;
    begin
      if schema || '.' || name in
        ( 'catalog.catalog', 'catalog._tables_and_views', 'catalog._materialized_views' ) then
        raise exception using message = 'Recursion not allowed for schema "catalog"', errcode = '42P19';
        return -2;
        end if;
      execute 'select count(*) from ' || schema || '.' || name
         into R;
      return R;
    end;
  $$;

-- ---------------------------------------------------------------------------------------------------------
create function CATALOG.count_tuples_dsp( schema text, name text )
  returns text
  language plpgsql
  as $$
    declare
      R integer;
    begin
      select CATALOG.count_tuples( schema, name ) into R;
      return to_char( R, '9,999,999' );
      exception
        when invalid_recursion then -- 38000
          return '(recursive)';
        when external_routine_exception then -- 38000
          return '(error)';
        when object_not_in_prerequisite_state then -- sqlstate = 55000
          return '(not ready)';
        when others then
          raise notice 'error while retrieving %.%: (%) %', schema, name, sqlstate, sqlerrm;
          -- raise exception 'error while retrieving %.%: (%) %', schema, name, sqlstate, sqlerrm;
          return '(???)';
    end;
  $$;


-- =========================================================================================================
-- VERSIONS
-- ---------------------------------------------------------------------------------------------------------
-- drop table if exists CATALOG.versions cascade;
create table CATALOG.versions (
  key           text primary key,
  version       text );

-- ---------------------------------------------------------------------------------------------------------
create function CATALOG.upsert_versions( ¶key text, ¶version text ) returns void
  language plpgsql volatile as $$
    begin
      insert into CATALOG.versions ( key, version ) values ( ¶key, ¶version )
        on conflict ( key ) do update set version = ¶version;
      end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT these values should in the future be read from options, package.json etc ### */
insert into CATALOG.versions values
  ( 'server', '3.0.3' ),
  ( 'api',    '2' );

-- do $$ begin perform CATALOG.upsert_versions( 'sthelse', '3.141' ); end; $$;
-- do $$ begin perform CATALOG.upsert_versions( 'api',     '3'     ); end; $$;

-- select * from CATALOG.versions;
-- \quit

-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
/* thx to http://stackoverflow.com/a/16632213 */
create view CATALOG._functions_with_defs_all as (
  select
      -- pp.*,
      pl.lanname                    as language_name,
      pn.nspname                    as schema_name,
      pp.proname                    as function_name,
      pp.proargnames                as parameters,
      pg_get_functiondef( pp.oid )  as def
  from pg_proc as pp
  inner join pg_namespace pn on ( pp.pronamespace = pn.oid )
  inner join pg_language  pl on ( pp.prolang      = pl.oid )
  );

-- ### TAINT this view contains return types, merge with _functions_with_defs_all
create view CATALOG._functions_and_return_types as (
  select
      pn.nspname                    as schema_name,
      pp.proname                    as function_name,
      pt.typname                    as type_name
  from pg_proc as pp
  inner join pg_namespace pn on ( pp.pronamespace = pn.oid )
  inner join pg_type      pt on ( pp.prorettype   = pt.oid ) );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG._functions_all as (
  select
      'f   '::text                              as t,
      schema_name                               as schema,
      function_name                             as name,
      language_name || '; ' || parameters::text as remarks
    from
      CATALOG._functions_with_defs_all
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG._functions as (
  select
      t                 as t,
      schema            as schema,
      name              as name,
      null::text        as size,
      remarks           as remarks
    from
      CATALOG._functions_all
  where true
    and schema not in ( 'information_schema' )
    and schema !~ '^pg_'
    -- and schema !~ '^_'
  );

-- ---------------------------------------------------------------------------------------------------------
create function CATALOG._get_table_remarks( insertable text, typed text )
returns text
language sql
as $$
  with v1 as (
    select
      case insertable when 'YES' then 'insertable'  else null end as insertable,
      case typed      when 'YES' then 'typed'       else null end as typed )
  select array_to_string( array[ insertable, typed ], ', ' ) from v1;
  $$;

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG._tables_and_views_all as (
  select
    case table_type when 'BASE TABLE' then 'rt' when 'VIEW' then 'rvo' else table_type end as t,
    table_schema  as schema,
    table_name    as name,
    CATALOG._get_table_remarks( is_insertable_into, is_typed ) as remarks
    -- case is_insertable_into when 'YES' then 'Y' else '' end as insertable,
    -- case is_typed           when 'YES' then 'Y' else '' end as typed
  from information_schema.tables
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG._tables_and_views as (
  select
      t                                           as t,
      schema                                      as schema,
      name                                        as name,
      null                                        as size,
      -- CATALOG.count_tuples_dsp( schema, name )   as size,
      remarks                                     as remarks
    from CATALOG._tables_and_views_all
    where true
      -- and t = 'rt'
      -- and schema not in (
      --   'pg_toast',
      --   'pg_catalog',
      --   'information_schema' )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG._materialized_views as (
  with v1 as (
    select
        'rvm'::text                       as t,
        schemaname                        as schema,
        matviewname                       as name,
        ''::text                          as remarks
      from pg_matviews
    )
    select
        t                                         as t,
        schema                                    as schema,
        name                                      as name,
        null                                      as size,
        -- CATALOG.count_tuples_dsp( schema, name ) as size,
        remarks                                   as remarks
      from v1
    );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG.catalog as (
  with v1 as (
              select * from CATALOG._tables_and_views
    union all select * from CATALOG._materialized_views
    union all select * from CATALOG._functions
    )
    select * from v1 order by t, schema, name
  );

/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
\quit


/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
/* # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### # ## # ### ##  */
/* thx to https://stackoverflow.com/a/46594226/7568091 */

create view CATALOG.dependencies as (
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
    1 );


-- ---------------------------------------------------------------------------------------------------------
-- create view CATALOG.catalog_tsn  as select t, schema, name, remarks from CATALOG.catalog order by t, schema, name;
-- create view CATALOG.catalog_stn  as select t, schema, name, remarks from CATALOG.catalog order by schema, t, name;
-- create view CATALOG.catalog_snt  as select t, schema, name, remarks from CATALOG.catalog order by schema, name, t;



-- select * from CATALOG.catalog;
-- select * from CATALOG._functions;
-- select * from CATALOG.catalog_stn;
-- select * from CATALOG.catalog_snt;

/*

Show indexes:

thx to https://stackoverflow.com/a/2213199/7568091

see also https://www.alberton.info/postgresql_meta_info.html
https://www.postgresql.org/docs/current/static/catalog-pg-index.html
https://www.postgresql.org/docs/current/static/catalog-pg-class.html


select
    i.oid,
    t.oid,
    t.relnamespace,
    -- *
    i.relname as index_name,
    t.relname as table_name,
    a.attname as column_name,
    t.relkind as type,
    ix.indisunique
from
    pg_class t,
    pg_class i,
    pg_index ix,
    pg_attribute a
where true
    and t.oid       = ix.indrelid
    and i.oid       = ix.indexrelid
    and a.attrelid  = t.oid
    and a.attnum    = any( ix.indkey )
    -- and t.relkind = 'r'
    and t.relname !~ '^(pg_|sql_)'
    -- and t.relname like 'test%'
order by
    t.relname,
    i.relname;
*/

/* https://raw.githubusercontent.com/datachomp/dotfiles/master/.psqlrc */
\set QUIET 1
-- formatting
\x auto

\set VERBOSITY verbose
\set ON_ERROR_ROLLBACK interactive
-- show execution times
\timing
-- limit paging
\pset pager off
-- replace nulls
\pset null ¤
\pset linestyle unicode
\pset border 2

-- colorize
--\set PROMPT1 '%[%033[33;1m%]%x%[%033[0m%]%[%033[1m%]%/%[%033[0m%]%R%# '
\set PROMPT1 '%[%033[1m%]%M %n@%/%R%[%033[0m%]%# '
--harolds
--\set PROMPT1 '%[%033[1m%]%M/%/%R%[%033[0m%]%# '
\set PROMPT2 '[more] %R > '



--logging
-- Use a separate history file per-database.
\set HISTFILE ~/.psql_history- :DBNAME
-- If a command is run more than once in a row, only store it once in the
-- history.
\set HISTCONTROL ignoredups

-- Autocomplete keywords (like SELECT) in upper-case, even if you started
-- typing them in lower case.
\set COMP_KEYWORD_CASE upper

-- greeting
\echo '\nWelcome, my magistrate\n'

\set clear '\\! clear;'

--helpful queries
\set uptime 'select now() - backend_start as uptime from pg_stat_activity where pid = pg_backend_pid();'
\set show_slow_queries 'SELECT (total_time / 1000 / 60) as total_minutes, (total_time/calls) as average_time, query FROM pg_stat_statements ORDER BY 1 DESC LIMIT 100;'
\set settings 'select name, setting,unit,context from pg_settings;'
\set conninfo 'select usename, count(*) from pg_stat_activity group by usename;'
\set activity 'select datname, pid, usename, application_name,client_addr, client_hostname, client_port, query, state from pg_stat_activity;'
\set waits 'SELECT pg_stat_activity.pid, pg_stat_activity.query, pg_stat_activity.waiting, now() - pg_stat_activity.query_start AS \"totaltime\", pg_stat_activity.backend_start FROM pg_stat_activity WHERE pg_stat_activity.query !~ \'%IDLE%\'::text AND pg_stat_activity.waiting = true;'
\set dbsize 'SELECT datname, pg_size_pretty(pg_database_size(datname)) db_size FROM pg_database ORDER BY db_size;'
\set tablesize 'SELECT nspname || \'.\' || relname AS \"relation\", pg_size_pretty(pg_relation_size(C.oid)) AS "size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN (\'pg_catalog\', \'information_schema\') ORDER BY pg_relation_size(C.oid) DESC LIMIT 40;'
\set uselesscol 'SELECT nspname, relname, attname, typname, (stanullfrac*100)::int AS null_percent, case when stadistinct &gt;= 0 then stadistinct else abs(stadistinct)*reltuples end AS \"distinct\", case 1 when stakind1 then stavalues1 when stakind2 then stavalues2 end AS \"values\" FROM pg_class c JOIN pg_namespace ns ON (ns.oid=relnamespace) JOIN pg_attribute ON (c.oid=attrelid) JOIN pg_type t ON (t.oid=atttypid) JOIN pg_statistic ON (c.oid=starelid AND staattnum=attnum) WHERE nspname NOT LIKE E\'pg\\\\_%\' AND nspname != \'information_schema\' AND relkind=\'r\' AND NOT attisdropped AND attstattarget != 0 AND reltuples &gt;= 100 AND stadistinct BETWEEN 0 AND 1 ORDER BY nspname, relname, attname;'


-- 4 helpful queries from radek http://radek.cc/2009/08/15/psqlrc-tricks-table-sizes/
\set trashindexes '( select s.schemaname as sch, s.relname as rel, s.indexrelname as idx, s.idx_scan as scans, pg_size_pretty(pg_relation_size(s.relid)) as ts, pg_size_pretty(pg_relation_size(s.indexrelid)) as "is" from pg_stat_user_indexes s join pg_index i on i.indexrelid=s.indexrelid left join pg_constraint c on i.indrelid=c.conrelid and array_to_string(i.indkey, '' '') = array_to_string(c.conkey, '' '') where i.indisunique is false and pg_relation_size(s.relid) > 1000000 and s.idx_scan < 100000 and c.confrelid is null order by s.idx_scan asc, pg_relation_size(s.relid) desc );'
\set missingindexes '( select src_table, dst_table, fk_name, pg_size_pretty(s_size) as s_size, pg_size_pretty(d_size) as d_size, d from ( select distinct on (1,2,3,4,5) textin(regclassout(c.conrelid)) as src_table, textin(regclassout(c.confrelid)) as dst_table, c.conname as fk_name, pg_relation_size(c.conrelid) as s_size, pg_relation_size(c.confrelid) as d_size, array_upper(di.indkey::int[], 1) + 1 - array_upper(c.conkey::int[], 1) as d from pg_constraint c left join pg_index di on di.indrelid = c.conrelid and array_to_string(di.indkey, '' '') ~ (''^'' || array_to_string(c.conkey, '' '') || ''( |$)'') join pg_stat_user_tables st on st.relid = c.conrelid where c.contype = ''f'' order by 1,2,3,4,5,6 asc) mfk where mfk.d is distinct from 0 and mfk.s_size > 1000000 order by mfk.s_size desc, mfk.d desc );'
\set _rtsize '(select table_schema, table_name, pg_relation_size( quote_ident( table_schema ) || \'.\' || quote_ident( table_name ) ) as size, pg_total_relation_size( quote_ident( table_schema ) || \'.\' || quote_ident( table_name ) ) as total_size  from information_schema.tables where table_type = \'BASE TABLE\' and table_schema not in (\'information_schema\', \'pg_catalog\') order by pg_relation_size( quote_ident( table_schema ) || \'.\' || quote_ident( table_name ) ) desc, table_schema, table_name)'
\set rtsize ':_rtsize;'
\set tsize '(select table_schema, table_name, pg_size_pretty(size) as size, pg_size_pretty(total_size) as total_size from (:_rtsize) x order by x.size desc, x.total_size desc, table_schema, table_name);'


-- Taken from https://github.com/heroku/heroku-pg-extras
-- via https://github.com/dlamotte/dotfiles/blob/master/psqlrc
\set bloat 'SELECT tablename as table_name, ROUND(CASE WHEN otta=0 THEN 0.0 ELSE sml.relpages/otta::numeric END,1) AS table_bloat, CASE WHEN relpages < otta THEN ''0'' ELSE pg_size_pretty((bs*(sml.relpages-otta)::bigint)::bigint) END AS table_waste, iname as index_name, ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::numeric END,1) AS index_bloat, CASE WHEN ipages < iotta THEN ''0'' ELSE pg_size_pretty((bs*(ipages-iotta))::bigint) END AS index_waste FROM ( SELECT schemaname, tablename, cc.reltuples, cc.relpages, bs, CEIL((cc.reltuples*((datahdr+ma- (CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta, COALESCE(c2.relname,''?'') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages, COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta FROM ( SELECT ma,bs,schemaname,tablename, (datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr, (maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2 FROM ( SELECT schemaname, tablename, hdr, ma, bs, SUM((1-null_frac)*avg_width) AS datawidth, MAX(null_frac) AS maxfracsum, hdr+( SELECT 1+count(*)/8 FROM pg_stats s2 WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename) AS nullhdr FROM pg_stats s, ( SELECT (SELECT current_setting(''block_size'')::numeric) AS bs, CASE WHEN substring(v,12,3) IN (''8.0'',''8.1'',''8.2'') THEN 27 ELSE 23 END AS hdr, CASE WHEN v ~ ''mingw32'' THEN 8 ELSE 4 END AS ma FROM (SELECT version() AS v) AS foo) AS constants GROUP BY 1,2,3,4,5) AS foo) AS rs JOIN pg_class cc ON cc.relname = rs.tablename JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = rs.schemaname AND nn.nspname <> ''information_schema'' LEFT JOIN pg_index i ON indrelid = cc.oid LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid) AS sml ORDER BY CASE WHEN relpages < otta THEN 0 ELSE bs*(sml.relpages-otta)::bigint END DESC;'
\set blocking 'select bl.pid as blocked_pid, ka.query as blocking_statement, now() - ka.query_start as blocking_duration, kl.pid as blocking_pid, a.query as blocked_statement, now() - a.query_start as blocked_duration from pg_catalog.pg_locks bl join pg_catalog.pg_stat_activity a on bl.pid = a.pid join pg_catalog.pg_locks kl join pg_catalog.pg_stat_activity ka on kl.pid = ka.pid on bl.transactionid = kl.transactionid and bl.pid != kl.pid where not bl.granted;'
\set cache_hit 'SELECT ''index hit rate'' as name, (sum(idx_blks_hit)) / sum(idx_blks_hit + idx_blks_read) as ratio FROM pg_statio_user_indexes union all SELECT ''cache hit rate'' as name, sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio FROM pg_statio_user_tables;'
\set index_size 'SELECT relname AS name, pg_size_pretty(sum(relpages*1024)) AS size FROM pg_class WHERE reltype=0 GROUP BY relname ORDER BY sum(relpages) DESC;'
\set index_usage 'SELECT relname, CASE idx_scan WHEN 0 THEN ''Insufficient data'' ELSE (100 * idx_scan / (seq_scan + idx_scan))::text END percent_of_times_index_used, n_live_tup rows_in_table FROM pg_stat_user_tables ORDER BY n_live_tup DESC;'
\set index_usage_adv 'SELECT * FROM (SELECT stat.relname AS table, stai.indexrelname AS index, CASE stai.idx_scan WHEN 0 THEN ''Insufficient data'' ELSE (100 * stai.idx_scan / (stat.seq_scan + stai.idx_scan))::text || ''%'' END hit_rate, CASE stat.idx_scan WHEN 0 THEN ''Insufficient data'' ELSE (100 * stat.idx_scan / (stat.seq_scan + stat.idx_scan))::text || ''%'' END all_index_hit_rate, ARRAY(SELECT pg_get_indexdef(idx.indexrelid, k + 1, true) FROM generate_subscripts(idx.indkey, 1) AS k ORDER BY k) AS cols, stat.n_live_tup rows_in_table FROM pg_stat_user_indexes AS stai JOIN pg_stat_user_tables AS stat ON stai.relid = stat.relid JOIN pg_index AS idx ON (idx.indexrelid = stai.indexrelid)) AS sub_inner ORDER BY rows_in_table DESC, hit_rate ASC;'
\set locks 'select pg_stat_activity.pid, pg_class.relname, pg_locks.transactionid, pg_locks.granted, substr(pg_stat_activity.query,1,30) as query_snippet, age(now(),pg_stat_activity.query_start) as "age" from pg_stat_activity,pg_locks left outer join pg_class on (pg_locks.relation = pg_class.oid) where pg_stat_activity.query <> ''<insufficient privilege>'' and pg_locks.pid=pg_stat_activity.pid and pg_locks.mode = ''ExclusiveLock'' order by query_start;'
\set long_running_queries 'SELECT pid, now() - pg_stat_activity.query_start AS duration, query AS query FROM pg_stat_activity WHERE pg_stat_activity.query <> ''''::text AND now() - pg_stat_activity.query_start > interval ''5 minutes'' ORDER BY now() - pg_stat_activity.query_start DESC;'
\set ps 'select pid, application_name as source, age(now(),query_start) as running_for, waiting, query as query from pg_stat_activity where query <> ''<insufficient privilege>'' AND state <> ''idle'' and pid <> pg_backend_pid() order by 3 desc;'
\set seq_scans 'SELECT relname AS name, seq_scan as count FROM pg_stat_user_tables ORDER BY seq_scan DESC;'
\set total_index_size 'SELECT pg_size_pretty(sum(relpages*1024)) AS size FROM pg_class WHERE reltype=0;'
\set unused_indexes 'SELECT schemaname || ''.'' || relname AS table, indexrelname AS index, pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size, idx_scan as index_scans FROM pg_stat_user_indexes ui JOIN pg_index i ON ui.indexrelid = i.indexrelid WHERE NOT indisunique AND idx_scan < 50 AND pg_relation_size(relid) > 5 * 8192 ORDER BY pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST, pg_relation_size(i.indexrelid) DESC;'
\set missing_indexes 'SELECT relname, seq_scan-idx_scan AS too_much_seq, case when seq_scan-idx_scan > 0 THEN ''Missing Index?'' ELSE ''OK'' END, pg_relation_size(relname::regclass) AS rel_size, seq_scan, idx_scan FROM pg_stat_all_tables WHERE schemaname=''public'' AND pg_relation_size(relname::regclass) > 80000 ORDER BY too_much_seq DESC;'

-- Development queries

\set sp 'SHOW search_path;'
\set clear '\\! clear;'
\set ll '\\! ls -lrt;'

\unset QUIET
