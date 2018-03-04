

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
create view CATALOG2.operators as ( select
    'operator'        as isa,
    x.oprowner        as owner_oid,
    x.oprnamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.oprname         as self_name
  from pg_operator           as x
  left join CATALOG2.schemas as s on ( x.oprnamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.oprowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.operator_classes as ( select
    'operator_class'  as isa,
    x.opcowner        as owner_oid,
    x.opcnamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.opcname         as self_name
  from pg_opclass     as x
  left join CATALOG2.schemas as s on ( x.opcnamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.opcowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.operator_families as ( select
    'operator_family' as isa,
    x.opfowner        as owner_oid,
    x.opfnamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.opfname         as self_name
  from pg_opfamily    as x
  left join CATALOG2.schemas as s on ( x.opfnamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.opfowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.types as ( select
    'type'            as isa,
    x.typowner        as owner_oid,
    x.typnamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.typname         as self_name
  from pg_type        as x
  left join CATALOG2.schemas as s on ( x.typnamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.typowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.extensions as ( select
    'extension'       as isa,
    x.extowner        as owner_oid,
    x.extnamespace    as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    s.self_name       as schema_name,
    x.extname         as self_name
  from pg_extension        as x
  left join CATALOG2.schemas as s on ( x.extnamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.extowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.constraints as ( select
    'constraint'      as isa,
    null::oid         as owner_oid,
    x.connamespace    as schema_oid,
    x.oid             as self_oid,
    null::text        as owner_name,
    s.self_name       as schema_name,
    x.conname         as self_name
  from pg_constraint        as x
  left join CATALOG2.schemas as s on ( x.connamespace  = s.self_oid )
  -- left join CATALOG2.roles   as r on ( x.conowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.languages as ( select
    'language'        as isa,
    x.lanowner        as owner_oid,
    null::oid         as schema_oid,
    x.oid             as self_oid,
    r.self_name       as owner_name,
    null::text        as schema_name,
    x.lanname         as self_name
  from pg_language        as x
  -- left join CATALOG2.schemas as s on ( x.lannamespace  = s.self_oid )
  left join CATALOG2.roles   as r on ( x.lanowner      = r.self_oid )
  );

-- ---------------------------------------------------------------------------------------------------------
create view CATALOG2.osn_catalog_with_oids as (
            select * from CATALOG2.roles
  union all select * from CATALOG2.schemas
  union all select * from CATALOG2.relations
  union all select * from CATALOG2.functions
  union all select * from CATALOG2.operators
  union all select * from CATALOG2.operator_classes
  union all select * from CATALOG2.operator_families
  union all select * from CATALOG2.types
  union all select * from CATALOG2.extensions
  union all select * from CATALOG2.constraints
  union all select * from CATALOG2.languages
  );
