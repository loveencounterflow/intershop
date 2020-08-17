

\ir './010-trm.sql'
\set filename update-os-env.sql
\set signal :green

-- ---------------------------------------------------------------------------------------------------------
/* Update OS.env to reflect current environment: */
/* thx to https://dba.stackexchange.com/a/134538/126933 */
/* 1) Old style, to be removed: */
-- \set os_environment `printenv`
/* 2) New style: */
-- ### TAINT this does not currently work for `intershop refresh-variables`
\set intershop_ng_settings `echo "$intershop_ng_settings"`


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
/* 1) Old style, to be removed: */
-- truncate U.variables;
-- with
--   v1 as ( select regexp_split_to_table( :'os_environment'::text, '\n' ) as setting  ),
--   v2 as ( select regexp_matches( setting, '^([^=]+)=(.*)$' ) as kv_pairs from v1    )
--   select U._set_env_variable( kv_pairs[ 1 ], kv_pairs[ 2 ] ) from v2 \g :devnull

-- ---------------------------------------------------------------------------------------------------------
/* 2) New style: */
truncate U.variables;
insert into U.variables ( select
    d.key                   as key,
    ( d.value )->>'value'   as value
  from jsonb_each ( :'intershop_ng_settings'::jsonb ) as d
  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$
  declare
    ¶row record;
  begin
    for ¶row in ( select key, value from U.variables where key ~ '^(os/env/[a-z])' ) loop
      ¶row.key :=  regexp_replace( ¶row.key, '^os/env/',  ''        );
      ¶row.key :=  regexp_replace( ¶row.key, '_',         '/', 'g'  );
      -- perform ¶( ¶row.key, ¶row.value );
      perform U.set_default( ¶row.key, ¶row.value );
      end loop;
    perform ¶( 'nodejs/versions/' || key, value ) from jsonb_each_text( U._nodejs_versions() );
    perform ¶( 'machine/'         || key, value ) from jsonb_each_text( U._get_architecture_etc() );
    perform ¶( 'machine/hostname', U._get_hostname() );
    end; $$;


/* ###################################################################################################### */
\quit

select * from OS.env where key ~ 'PY|PAGER|^[a-z]';
select ( :'intershop_ng_settings'::text ) = '';
select ( :'intershop_ng_settings'::jsonb )->>'intershop/plpython3u/syspathprefix'; -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
select ( :'intershop_ng_settings'::jsonb )->>'nodejs/versions'; -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- select * from U.variables where key !~ '^os/' order by key;
select * from U.variables where key ~ 'intershop/plpython3u/syspathprefix';
select ( :'intershop_ng_settings'::jsonb )->>'intershop/plpython3u/syspathprefix';
xxx




