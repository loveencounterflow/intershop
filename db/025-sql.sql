

/* Creates / executes dynamical SQL for typical use cases */


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists SQL cascade;
create schema SQL;

/* thx to https://stackoverflow.com/a/12530727/7568091

To get the type name from an OID, just cast it to regtype:

```sql
SELECT  700::oid::regtype -- real
```

To get the type of any columns (or variable in plpgsql), use pg_typeof():

```sql
SELECT  pg_typeof(1::real) -- real
```

Gives you an answer of type regtype which is displayed as text in psql or pgAdmin. You can cast it to text
explicitly if needed:

```sql
SELECT  pg_typeof(1::real)::text -- real
```

There is also this "big list", vulgo catalog table pg_type, where types are registered. This can be big,
have a peek:

```sql
SELECT * from pg_type LIMIT 10;
```
*/


-- ---------------------------------------------------------------------------------------------------------
create table SQL.oids_and_types as ( select
      typname::text as name,
      oid           as oid
    from pg_type order by oid );

-- ---------------------------------------------------------------------------------------------------------
create unique index on SQL.oids_and_types ( name );
create unique index on SQL.oids_and_types ( oid );

/* Some aliases that should be fixed:
  int4                  -> integer
  int8                  -> bigint
  bool                  -> boolean
  double precision      -> float
*/
update SQL.oids_and_types set name = 'boolean'    where oid =       'boolean'::regtype::oid;
update SQL.oids_and_types set name = 'integer'    where oid =       'integer'::regtype::oid;
update SQL.oids_and_types set name = 'float'      where oid =         'float'::regtype::oid;
update SQL.oids_and_types set name = 'bigint'     where oid =        'bigint'::regtype::oid;
update SQL.oids_and_types set name = 'text[]'     where oid =        'text[]'::regtype::oid;
update SQL.oids_and_types set name = 'jsonb[]'    where oid =       'jsonb[]'::regtype::oid;
update SQL.oids_and_types set name = 'boolean[]'  where oid =     'boolean[]'::regtype::oid;
update SQL.oids_and_types set name = 'integer[]'  where oid =     'integer[]'::regtype::oid;
update SQL.oids_and_types set name = 'float[]'    where oid =       'float[]'::regtype::oid;
update SQL.oids_and_types set name = 'bigint[]'   where oid =      'bigint[]'::regtype::oid;

select * from SQL.oids_and_types where oid = 1009;

-- ---------------------------------------------------------------------------------------------------------
/* aliases for names of DB objects; see table at https://www.postgresql.org/docs/current/static/datatype-oid.html */
create domain SQL.name_of_function   as regproc;         /* pg_proc       */
create domain SQL.name_of_operator   as regoper;         /* pg_operator   */
create domain SQL.name_of_relation   as regclass;        /* pg_class      */
create domain SQL.name_of_data_type  as regtype;         /* pg_type       */
create domain SQL.name_of_role       as regrole;         /* pg_authid     */
create domain SQL.name_of_schema     as regnamespace;    /* pg_namespace  */
-- create domain NAMEOF.numeric_object_identifier     as oid;             /* any           */
-- create domain NAMEOF.function_with_atypes          as regprocedure;    /* pg_proc       */
-- create domain NAMEOF.operator_with_atypes          as regoperator;     /* pg_operator   */
-- create domain NAMEOF.text_search_configuration     as regconfig;       /* pg_ts_config  */
-- create domain NAMEOF.text_search_dictionary        as regdictionary;   /* pg_ts_dict    */

-- ---------------------------------------------------------------------------------------------------------
-- create function SQL.from_text_facets( U.text_facet[] ) immutable strict language plpgsql as $$
--   $$;

-- select SQL.from_text_facets( array_agg( ))

\quit

