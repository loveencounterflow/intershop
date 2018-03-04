

-- ---------------------------------------------------------------------------------------------------------
create schema CATALOG2;


-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.roles as ( select
    'role'            as isa,
    null::oid         as owner_oid,
    null::oid         as schema_oid,
    x.oid             as self_oid,
    null::name        as owner_name,
    null::name        as schema_name,
    x.rolname         as self_name
  from pg_roles as x );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.schemas as ( select
    'schema'          as isa,
    null::oid         as owner_oid,
    null::oid         as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    null::name        as schema_name,
    x.nspname         as self_name
  from pg_namespace           as x
  left join CATALOG2.roles   as r on ( x.nspowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.relations as ( select
    'relation'        as isa,
    x.relowner        as owner_oid,
    x.relnamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.relname         as self_name
  from pg_class               as x
  left join CATALOG2.schemas as s on ( x.relnamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.relowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.functions as ( select
    'function'        as isa,
    x.proowner        as owner_oid,
    x.pronamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.proname         as self_name
  from pg_proc                as x
  left join CATALOG2.schemas as s on ( x.pronamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.proowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.osn_catalog_with_oids as (
            select * from CATALOG2.roles
  union all select * from CATALOG2.schemas
  union all select * from CATALOG2.relations
  union all select * from CATALOG2.functions
  );
