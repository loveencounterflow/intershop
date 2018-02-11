

\ir './010-trm.sql'

-- ---------------------------------------------------------------------------------------------------------
/* Update OS.env to reflect current environment: */
/* thx to https://dba.stackexchange.com/a/134538/126933 */
\set os_environment `printenv`
with
  v1 as ( select regexp_split_to_table( :'os_environment'::text, '\n' ) as setting  ),
  v2 as ( select regexp_matches( setting, '^([^=]+)=(.*)$' ) as kv_pairs from v1    )
  select OS._set_env_variable( kv_pairs[ 1 ], kv_pairs[ 2 ] ) from v2 \g :devnull

-- ---------------------------------------------------------------------------------------------------------
do $$
  declare
    ¶row record;
  begin
    for ¶row in ( select key, value from U.variables where key ~ '^os/env/intershop_' ) loop
      ¶row.key :=  regexp_replace( ¶row.key, '^os/env/intershop_paths_',  'intershop/paths/'  );
      ¶row.key :=  regexp_replace( ¶row.key, '^os/env/intershop_db_',     'intershop/db/'     );
      ¶row.key :=  regexp_replace( ¶row.key, '^os/env/intershop_',        'intershop/'        );
      perform ¶( ¶row.key, ¶row.value );
      end loop;
    perform ¶( 'nodejs/versions/' || key, value ) from jsonb_each_text( OS._nodejs_versions() );
    perform ¶( 'machine/'         || key, value ) from jsonb_each_text( OS._get_architecture_etc() );
    perform ¶( 'machine/hostname', OS._get_hostname() );
    end; $$;

/* ###################################################################################################### */
\quit

select * from OS.env where key ~ 'PY|PAGER|^[a-z]';

