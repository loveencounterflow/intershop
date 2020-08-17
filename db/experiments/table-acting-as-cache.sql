

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
drop schema if exists CACHE cascade; create schema CACHE;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
create table CACHE.products (
    n           integer not null,
    factor      integer not null,
    result      integer,
    nosuchvalue boolean not null default false,
  primary key ( n, factor ) );

insert into CACHE.products ( n, factor, result ) values
  ( 3, 1,  3 ),
  ( 3, 2,  6 ),
  ( 3, 3,  9 );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
create function CACHE.get_product( ¶n integer, ¶factor integer )
  returns integer strict volatile language plpgsql as $$
  declare
    ¶row        record;
  begin
    select into ¶row * from CACHE.products where n = ¶n and factor = ¶factor;
    if ¶row.result is not null then return ¶row.result; end if;
    if ¶row.nosuchvalue then return null; end if;
    -- .....................................................................................................
    -- try to compute value, this may or may not be successful. There are two variants for missing values,
    -- confirmed and unconfirmed lacunae. Unconfirmed lacunae will continue to cause errors whenever they
    -- get requested, but confirmed lacunae have `nosuchvalue` set to `true` and will cause a default value
    --  of `null` to be returned:
    if ¶n != 13 then
      insert into CACHE.products ( n, factor, result ) ( select
          ¶n                    as n,
          ¶factor               as factor,
          ¶n * ¶factor          as result );
    else
      if ¶factor % 2 = 0 then
        insert into CACHE.products ( n, factor, result, nosuchvalue ) ( select
          ¶n                    as n,
          ¶factor               as factor,
          null                  as result,
          true                  as nosuchvalue );
        end if;
      end if;
    -- .....................................................................................................
    select into ¶row * from CACHE.products where n = ¶n and factor = ¶factor;
    if ¶row.result is not null then return ¶row.result; end if;
    if ¶row.nosuchvalue then return null; end if;
    -- .....................................................................................................
    raise sqlstate 'HBX02' using message = '#HBX02-1 Key Error', hint = format(
      'unable to retrieve result for ¶n: %s, ¶factor: %s', ¶n, ¶factor );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
-- ### TAINT could/should be procedure? ###
create function CACHE._create_caching_function(
  ¶schema_name                text,
  ¶function_name              text,
  ¶parameter_names_and_types  text[],
  ¶return_term                text,
  ¶return_type                text,
  ¶row_match_condition        text,
  ¶row_accept_if              text,
  ¶update_cache               text
  )
  returns text volatile language plpgsql as $outer$
  declare
    ¶s      text;
    ¶p      text;
    ¶m      text;
    ¶z      text;
    ¶k      text;
    ¶q      text;
  begin
    -- .....................................................................................................
    ¶p :=  ( select string_agg( format( '%s %s',   x[ 1 ], x[ 2 ]  ), ', ' ) from U.unnest_2d_1d( ¶parameter_names_and_types ) as x );
    ¶k :=  ( select string_agg( format( '%s: %%s', x[ 1 ]          ), ', ' ) from U.unnest_2d_1d( ¶parameter_names_and_types ) as x );
    ¶q :=  ( select string_agg( format( '%s',      x[ 1 ]          ), ', ' ) from U.unnest_2d_1d( ¶parameter_names_and_types ) as x );
    -- .....................................................................................................
    ¶s := '';
    ¶s := ¶s || format( $$  create function %s.%s( %s )                           $$, ¶schema_name, ¶function_name, ¶p );
    ¶s := ¶s || format( $$    returns %s strict volatile language plpgsql as $f$  $$, ¶return_type );
    ¶s := ¶s ||         $$    declare                                             $$;
    ¶s := ¶s ||         $$      r record;                                         $$;
    ¶s := ¶s ||         $$    begin                                               $$;
    -- .....................................................................................................
    ¶m := '';
    ¶m := ¶m || format( $$ select into r * from CACHE.products where %s;          $$, ¶row_match_condition );
    ¶m := ¶m || format( $$ if %s then return %s; end if;                          $$, ¶row_accept_if, ¶return_term );
    ¶m := ¶m ||         $$ if r.nosuchvalue then return null; end if;             $$;
    -- .....................................................................................................
    ¶z := '';
    ¶z := ¶z ||         $$ raise sqlstate 'CHX02' using                           $$;
    ¶z := ¶z ||         $$ message = format( '#CHX02-1 Key Error: ' ||            $$;
    ¶z := ¶z || format( $$ 'unable to retrieve result for %s', %s );              $$, ¶k, ¶q );
    ¶z := ¶z ||         $$ end; $f$;                                              $$;
    -- .....................................................................................................
    return ¶s || ¶m || ¶update_cache || ¶m || ¶z;
  end; $outer$;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
-- ### TAINT could/should be procedure? ###
create function CACHE.create_caching_function(
  ¶schema_name                text,
  ¶function_name              text,
  ¶parameter_names_and_types  text[],
  ¶return_term                text,
  ¶return_type                text,
  ¶row_match_condition        text,
  ¶row_accept_if              text,
  ¶update_cache               text )
  returns void volatile language plpgsql as $$
    begin
    execute CACHE._create_caching_function(
      ¶schema_name, ¶function_name,
      ¶parameter_names_and_types, ¶return_term, ¶return_type,
      ¶row_match_condition, ¶row_accept_if,
      ¶update_cache );
      end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset

select * from CACHE.products order by n, factor;
select * from CACHE.get_product( 4, 12 );
select * from CACHE.products order by n, factor;
select * from CACHE.get_product( 13, 12 );
select * from CACHE.products order by n, factor;
-- select * from CACHE.get_product( 13, 13 );

select * from CACHE.create_caching_function(
  'cache', 'get_product_generated',
  array[ array[ '¶n', 'integer' ], array[ '¶factor', 'integer' ] ],
  'r.result',
  'integer',
  'n = ¶n and factor = ¶factor',
  'r.result is not null',
  $$ if ¶n != 13 then
      insert into CACHE.products ( n, factor, result ) ( select
          ¶n                    as n,
          ¶factor               as factor,
          ¶n * ¶factor          as result );
    else
      if ¶factor % 2 = 0 then
        insert into CACHE.products ( n, factor, result, nosuchvalue ) ( select
          ¶n                    as n,
          ¶factor               as factor,
          null                  as result,
          true                  as nosuchvalue );
        end if;
      end if; $$ );

select * from CACHE.products order by n, factor;
select * from CACHE.get_product_generated( 4, 12 );
select * from CACHE.products order by n, factor;
select * from CACHE.get_product_generated( 13, 12 );
select * from CACHE.get_product_generated( 13, 14 );
select * from CACHE.get_product_generated( 144, 144 );
select * from CACHE.products order by n, factor;
select * from CACHE.get_product_generated( 13, 13 );

/* ###################################################################################################### */
\echo :red ———{ :filename 22 }———:reset
\quit



