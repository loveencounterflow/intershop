
-- https://blog.sql-workbench.eu/post/query-to-json/

-- Converting query results to JSON (2019-04-23)

-- In my post about dynamic SQL I showed how PostgreSQL’s query_to_xml() could be used to run dynamic SQL and
-- process the result in a regular SQL query.

-- If you prefer to deal with JSON, rather than XML, it’s quite easy to write a corresponding query_to_jsonb()
-- function.

create or replace function query_to_jsonb(p_query text, p_include_nulls boolean default false)
  returns jsonb
as
$$
declare
  l_sql text;
  l_result jsonb;
begin
  l_sql := 'select jsonb_agg(';

  if p_include_nulls then
    l_sql := l_sql || 'jsonb_strip_nulls(';
  end if;

  l_sql := l_sql || 'to_jsonb(t)';

  if p_include_nulls then
    l_sql := l_sql || ')';
  end if;

  l_sql := l_sql || ') from (' || p_query || ') t';

  execute l_sql
    into l_result;

  return l_result;
end;
$$
language plpgsql;

-- This makes the example query to return the row count for every table a lot easier to read:

-- select schemaname, tablename,
--        (query_to_jsonb(format('select count(*) as cnt from %I.%I', schemaname, tablename), false) -> 0 ->> 'cnt')::int
-- from pg_catalog.pg_tables
-- where schemaname = 'public'
-- SQL

