/*

### NOTE this code has migrated to `intershop-lazy`, an InterShop add-on. ###


*/

-- \set ECHO queries
begin transaction;

/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
-- ---------------------------------------------------------------------------------------------------------
-- \set filename interplot/db/tests/080-intertext.sql
\set filename interplot/db/900-dev.sql
\set signal :blue

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists LAZY cascade; create schema LAZY;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create table LAZY.facets (
  bucket        text    not null,
  key           jsonb   not null,
  value         jsonb,
  primary key ( bucket, key ) );



-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
drop schema if exists MYSCHEMA cascade; create schema MYSCHEMA;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create view MYSCHEMA.products as ( select
      ( key->0 )::integer as n,
      ( key->1 )::integer as factor,
      ( value  )::integer as product
    from LAZY.facets
    where bucket = 'MYSCHEMA.products' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create function MYSCHEMA._get_product_key( ¶n integer, ¶factor integer )
  returns jsonb immutable strict language sql as $$ select ( format( '[%s,%s]', ¶n, ¶factor ) )::jsonb; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
-- ### NOTE consider to allow variant where update method returns key, value instead of inserting itself;
-- the latter is more general as it may insert an arbitrary number of adjacent / related / whatever items
create function MYSCHEMA._update_products_cache( ¶n integer, ¶factor integer )
  returns void volatile strict language plpgsql as $$ declare
    ¶bucket text  :=  'MYSCHEMA.products';
    ¶key    jsonb :=  MYSCHEMA._get_product_key( ¶n, ¶factor );
  begin
    if ¶n != 13 then
      insert into LAZY.facets ( bucket, key, value ) values ( ¶bucket, ¶key, to_jsonb( ¶n * ¶factor ) );
    else
      if ( ¶factor % 2 ) = 0 then
        insert into LAZY.facets ( bucket, key, value ) values ( ¶bucket, ¶key, null );
        end if;
      end if;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
-- ### NOTE consider to allow variant where update method returns key, value instead of inserting itself;
-- the latter is more general as it may insert an arbitrary number of adjacent / related / whatever items
create function MYSCHEMA.get_product_0( ¶n integer, ¶factor integer )
  returns integer volatile strict language plpgsql as $$ declare
    ¶bucket text  :=  'MYSCHEMA.products';
    ¶key    jsonb :=  MYSCHEMA._get_product_key( ¶n, ¶factor );
    ¶value  jsonb;
  begin
    ¶value := ( select value from LAZY.facets where bucket = ¶bucket and ¶key = key );
    if ¶value is not null then return ¶value::integer; end if;
    perform MYSCHEMA._update_products_cache( ¶n, ¶factor );
    ¶value := ( select value from LAZY.facets where bucket = ¶bucket and ¶key = key );
    if ¶value is not null then return ¶value::integer; end if;
    raise sqlstate 'XXX02' using message = format( '#XXX02-1 Key Error: unable to retrieve result for ¶n: %s, ¶factor: %s', ¶n, ¶factor );
    end; $$;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
-- ### TAINT could/should be procedure? ###
create function LAZY.create_cached_getter_function(
  function_name     text,
  parameter_names   text[],
  parameter_types   text[],
  return_type       text,
  bucket            text default null,
  get_key           text default null,
  get_update        text default null,
  perform_update    text default null,
  caster            text default null ) returns text volatile language plpgsql as $outer$
  declare
    ¶bucket text;
    ¶p      text;
    ¶k      text;
    ¶n      text;
    ¶v      text;
    ¶r      text;
    ¶u      text;
    ¶x      text;
    R       text;
    -- ¶z      text;
    -- ¶q      text;
  begin
    -- .....................................................................................................
    -- ### TAINT validate both arrays have at least one element, same number of elements
    ¶p := ( select string_agg( format( '%s %s', name, parameter_types[ r1.nr ] ), ', ' )
      from unnest( parameter_names ) with ordinality as r1 ( name, nr ) );
    ¶n := ( select string_agg( n, ', ' ) from unnest( parameter_names ) as x ( n ) );
    ¶x := ( select string_agg( n || ': %s', ', ' ) from unnest( parameter_names ) as x ( n ) );
    -- .....................................................................................................
    if get_key is null then
      ¶k := format( 'jsonb_build_array( %s )', ¶n );
    else
      ¶k := format( '%s( %s )', get_key, ¶n );
      end if;
    -- .....................................................................................................
    ¶bucket :=  coalesce( bucket, function_name );
    ¶v      :=  format( '%s( ¶value )::%s', coalesce( caster, '' ), return_type );
    -- .....................................................................................................
    if ( get_update is null ) and ( perform_update is null ) then
      raise sqlstate 'LZ120' using message =
      '#LZ120 Type Error: one of get_update, perform_update must be non-null'; end if;
    if ( get_update is not null ) and ( perform_update is not null ) then
      raise sqlstate 'LZ120' using message =
      '#LZ120 Type Error: one of get_update, perform_update must be null'; end if;
    -- .....................................................................................................
    R  := '';
    R  := R  || format( e'create function %s( %s )                                  \n', function_name, ¶p );
    R  := R  || format( e'  returns %s strict volatile language plpgsql as $f$      \n', return_type );
    R  := R  ||         e'  declare                                                 \n';
    R  := R  || format( e'    ¶key    jsonb := %s;                                  \n', ¶k );
    R  := R  ||         e'    ¶value  jsonb;                                        \n';
    R  := R  ||         e'  begin                                                   \n';
    -- .....................................................................................................
    ¶r := '';
    ¶r := ¶r ||         e'  -- ---------------------------------------------------\n';
    ¶r := ¶r ||         e'  ¶value := ( select value from LAZY.facets             \n';
    ¶r := ¶r || format( e'    where bucket = %L and key = ¶key );                 \n', ¶bucket );
    ¶r := ¶r || format( e'  if ¶value is not null then return %s; end if;         \n', ¶v );
    R  := R  || ¶r;
    -- .....................................................................................................
    R  := R  ||         e'  -- -----------------------------------------------------\n';
    if ( get_update is not null ) then
      R  := R  || format( e'  ¶value := %s;\n', get_update );
      R  := R  ||         e'  insert into LAZY.facets ( bucket, key, value ) values \n';
      R  := R  ||         e'    ( ¶bucket, ¶key, to_jsonb( ¶value ) );              \n';
      R  := R  || format( e'  if ¶value is not null then return ¶value::%s; end if; \n', return_type );
    else
      R  := R  || format( e'  %s( %s );\n', perform_update, ¶n );
      R  := R  || ¶r;
      end if;
    -- .....................................................................................................
    R  := R  ||         e'  -- -----------------------------------------------------\n';
    R  := R  ||         e'  raise sqlstate ''LZ120'' using                          \n';
    R  := R  ||         e'    message = format( ''#LZ120-1 Key Error: '' ||         \n';
    R  := R  || format( e'    ''unable to retrieve result for %s'', %s );           \n', ¶x, ¶n );
    R  := R  ||         e'  end; $f$;';
    -- .....................................................................................................
    return R;
  end; $outer$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- ### TAINT could/should be procedure? ###
create function LAZY.create_caching_function(
  ¶schema_name                text,
  ¶function_name              text,
  ¶parameter_names_and_types  text[],
  ¶return_term                text,
  ¶return_type                text,
  ¶row_match_condition        text,
  ¶row_accept_if              text,
  ¶perform_update               text )
  returns void volatile language plpgsql as $$
    begin
    execute LAZY._create_caching_function(
      ¶schema_name, ¶function_name,
      ¶parameter_names_and_types, ¶return_term, ¶return_type,
      ¶row_match_condition, ¶row_accept_if,
      ¶perform_update );
      end; $$;

select LAZY.create_cached_getter_function(
  function_name   => 'MYSCHEMA.get_product_1',          -- name of function to be created
  parameter_names => '{¶n,¶factor}',
  parameter_types => '{integer,integer}',
  return_type     => 'integer',                         -- applied to cached value or value returned by caster
  bucket          => 'MYSCHEMA.products',               -- optional, defaults to `function_name`
  get_key         => 'MYSCHEMA._get_product_key',       -- optional, default is JSON list / object of values
  get_update      => null,                              -- optional, this x-or `perform_update` must be given
  perform_update  => 'MYSCHEMA._update_products_cache', -- optional, this x-or `get_update` must be given
  caster          => null                               -- optional, to transform JSONB value in to `return_type` (after `caster()` called where present)
  );

select LAZY.create_cached_getter_function(
  function_name   => 'MYSCHEMA.get_product_2',          -- name of function to be created
  parameter_names => '{¶n,¶factor}',
  parameter_types => '{integer,integer}',
  return_type     => 'integer',                         -- applied to cached value or value returned by caster
  bucket          => null,                              -- optional, defaults to `function_name`
  get_key         => null,                              -- optional, default is JSON list / object of values
  get_update      => '¶n * ¶factor',                    -- optional, this x-or `perform_update` must be given
  perform_update  => null,                              -- optional, this x-or `get_update` must be given
  caster          => 'cast_my_value'                    -- optional, to transform JSONB value in to `return_type` (after `caster()` called where present)
  );

select * from LAZY.facets order by bucket, key;
select * from MYSCHEMA.get_product_1( 4, 12 );
select * from MYSCHEMA.get_product_1( 5, 12 );
select * from MYSCHEMA.get_product_1( 6, 12 );
select * from LAZY.facets order by bucket, key;
select * from MYSCHEMA.products;
select * from MYSCHEMA.get_product_1( 13, 12 );

/* ###################################################################################################### */
\echo :red ———{ :filename 22 }———:reset
\quit


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset

-- select * from MYSCHEMA.products order by n, factor;
-- select * from MYSCHEMA.get_product( 13, 12 );
-- select * from MYSCHEMA.products order by n, factor;
-- -- select * from MYSCHEMA.get_product( 13, 13 );

-- select * from LAZY.create_caching_function(
--   'cache', 'get_product_generated',
--   array[ array[ '¶n', 'integer' ], array[ '¶factor', 'integer' ] ],
--   'r.result',
--   'integer',
--   'n = ¶n and factor = ¶factor',
--   'r.result is not null'
--   );

-- select * from MYSCHEMA.products order by n, factor;
-- select * from MYSCHEMA.get_product_generated( 4, 12 );
-- select * from MYSCHEMA.products order by n, factor;
-- select * from MYSCHEMA.get_product_generated( 13, 12 );
-- select * from MYSCHEMA.get_product_generated( 13, 14 );
-- select * from MYSCHEMA.get_product_generated( 144, 144 );
-- select * from MYSCHEMA.products order by n, factor;
-- select * from MYSCHEMA.get_product_generated( 13, 13 );



