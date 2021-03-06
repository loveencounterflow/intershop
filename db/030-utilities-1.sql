
/*

888     888
888     888
888     888
888     888
888     888
888     888
Y88b. .d88P
 "Y88888P"

*/

-- ---------------------------------------------------------------------------------------------------------
create schema U;

-- ---------------------------------------------------------------------------------------------------------
create or replace function echo( text, anyelement ) returns anyelement volatile language plpgsql as $$
  begin raise notice '(%) %', $1, $2; return $2; end; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function echo( text, anyelement ) is 'Diagnostic function that simplifies issuing notices; it
  returns its second argument so it can be inserted into queries to ''peek inside'', as it were.';

-- .........................................................................................................
create domain U.null_text                   as text     check ( value is null                 );
create domain U.null_integer                as integer  check ( value is null                 );
create domain U.nonnegative_integer         as integer  check ( value >= 0                    );
create domain U.natural_number              as integer  check ( value >= 1                    );
create domain U.nonempty_text               as text     check ( value != ''                   );
create domain U.chr                         as text     check ( character_length( value ) = 1 );
create domain U.unsigned_integer_literal    as text     check ( value ~ '^[0-9]+$'            );
-- .........................................................................................................
create type U.triple_facet            as ( key text,  type text,  value text      );
create type U.text_facet              as ( key text,              value text      );
create type U.jsonb_facet             as ( key text,              value jsonb     );
create type U.integer_facet           as ( key text,              value integer   );
create type U.float_facet             as ( key text,              value float     );
-- .........................................................................................................
create type U.text_line               as ( linenr U.natural_number, line  text  );
create type U.fields_line             as ( linenr U.natural_number, line  text  );
create type U.jsonb_line              as ( linenr U.natural_number, value jsonb );


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */
/* thx to https://stackoverflow.com/a/24006432/7568091 */
/*

functions to turn a select into json, text, display it:

-- select array_to_json(  array_agg( t ) ) from ( select 1 as a union all select 2 ) as t;
-- select json_agg( t ) from ( select 1 as a union all select 2 ) as t;
-- \quit

    X := json_agg( t )::text from ( select aid, act from _FSM2_.journal where bid = new.bid union select 111111, new.act ) as t;
    perform log( '00902', 'existing', X );
    X := json_agg( t )::text from ( select new ) as t;
*/
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */
/*

turn a table with keys and values into a single JSON object:


drop table if exists d cascade;
create table d ( key text, value text );
insert into d values
  ( 'key_A', 'value_a' ),
  ( 'key_B', 'value_b' );

with  keys    as ( select array_agg( key    order by key ) as k from d ),
      values  as ( select array_agg( value  order by key ) as v from d )
  select jsonb_object( keys.k, values.v ) from keys, values;

               jsonb_object
------------------------------------------
 {"key_A": "value_a", "key_B": "value_b"}

*/
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */

-- -- ---------------------------------------------------------------------------------------------------------
-- create function T._is_distinct_from( anyelement, anyelement ) returns boolean immutable language sql as $$
--   select $1 is distinct from $2; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- create function T._is_distinct_from( anyarray, anyarray ) returns boolean immutable language sql as $$
--   select $1 is distinct from $2; $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.text_array_from_json( jsonb )
  /* Accepts a textual JSON-compliant representation of an array and returns an SQL `array` with text
  elements. This is needed primarily to pass `variadic text[]` arguments to public / RPC UDFs.
  Thx to https://dba.stackexchange.com/a/54289/126933 */
  returns text[] immutable language sql as $$
  select array( select jsonb_array_elements_text( $1 ) )
  $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.bigint_array_from_json( jsonb )
  /* Accepts a textual JSON-compliant representation of an array and returns an SQL `array` with bigint
  elements. This is needed primarily to pass `variadic bigint[]` arguments to public / RPC UDFs.
  Thx to https://dba.stackexchange.com/a/54289/126933 */
  returns bigint[] immutable language sql as $$
  select array( select jsonb_array_elements_text( $1 ) )::bigint[]
  $$;

/* thx to https://stackoverflow.com/a/37278190/7568091 (J. Raczkiewicz) */
create function U.jsonb_diff( a jsonb, b jsonb )
returns jsonb immutable language plpgsql as $$
  declare
    R             jsonb;
    object_result jsonb;
    n             int;
    value         record;
  begin
    if jsonb_typeof(a) = 'null' then return b; end if;
    -- .....................................................................................................
    R = a;
    for value in select * from jsonb_each( a ) loop
      R = R || jsonb_build_object( value.key, null );
      end loop;
    -- .....................................................................................................
    for value in select * from jsonb_each( b ) loop
      -- ...................................................................................................
      if jsonb_typeof( a->value.key ) = 'object' and jsonb_typeof( b->value.key ) = 'object' then
        object_result = U.jsonb_diff( a->value.key, b->value.key );
        -- .................................................................................................
        /* check if R is not empty */
        n := ( select count(*) from jsonb_each( object_result ) );
        -- .................................................................................................
        if n = 0 then
          --if empty, remove:
          R := R - value.key;
        -- .................................................................................................
        else
          R := R || jsonb_build_object( value.key, object_result );
          end if;
      -- ...................................................................................................
      elsif a->value.key = b->value.key then
        R = R - value.key;
      else
        R = R || jsonb_build_object( value.key,value.value );
        end if;
      end loop;
    -- .....................................................................................................
    return R;
    end;
    $$;

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://stackoverflow.com/a/39812817/7568091 */
create function U.count_jsonb_keys( diff jsonb )
returns integer immutable language plpgsql as $$
  begin
    select array_upper( array( select jsonb_object_keys( diff ) ), 1 );
    end;
    $$;

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://stackoverflow.com/a/39812817/7568091 */
create function U.truth( boolean )
returns text immutable language plpgsql as $$
  begin
    case $1
      when true   then  return 'true';
      when false  then  return 'false';
      else              return '∎';
      end case;
    end; $$;

  -- declare
  --   green   text;
  --   red     text;
  --   reset   text;
  -- begin
  --   select into reset value from TRM.colors where key = 'reset';
  --   if $1 then
  --     select into green value from TRM.colors where key = 'green';
  --     return green  || 'true'  || reset;
  --   else
  --     select into red   value from TRM.colors where key = 'red';
  --     return red    || 'false' || reset;
  --     end if;
  --   end;
  --   $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- do $$ begin
--   perform ¶( 'username', current_user );
--   end; $$;

-- =========================================================================================================
-- CONVERSION TO JSONB
-- ---------------------------------------------------------------------------------------------------------
create function jb( ¶x text ) returns jsonb immutable strict language sql as $$
  select to_jsonb( ¶x ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function jb( ¶x anyelement ) returns jsonb immutable strict language sql as $$
  select to_jsonb( ¶x ); $$;

comment on function jb( text )        is '`jb()` works almost like `to_jsonb()`, except that strings do not have to be quoted.';
comment on function jb( anyelement )  is '`jb()` works almost like `to_jsonb()`, except that strings do not have to be quoted.';

-- ---------------------------------------------------------------------------------------------------------
set role dba;
/* Expects an SQL query as text that delivers two columns, the first being names and the second JSONb
  values of the object to be built. */
create function U.facets_as_jsonb_object( sql_ text ) returns jsonb stable language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import json as JSON
  R             = {}
  result        = plpy.execute( sql_ )
  ( k, v, )     = result.colnames()
  for row in result:
    if row[ v ] == None:
      R[ row[ k ] ] = None
      continue
    R[ row[ k ] ] = JSON.loads( row[ v ] )
  return JSON.dumps( R ) $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
/* Expects an SQL query as text that delivers two columns, the first being names and the second JSONb
  values of the object to be built. */
create function U.row_as_jsonb_object( sql_ text ) returns jsonb stable language plpython3u as $$
  plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  import json as JSON
  R                   = {}
  result              = plpy.execute( sql_ )
  keys_and_typenames  = ctx.keys_and_typenames_from_result( ctx, result )
  #.........................................................................................................
  if len( result ) != 1:
    raise ValueError( "expected 1 result row, got " + str( len( result ) ) + " from query " + repr( sql_ ) )
  #.........................................................................................................
  for row in result:
    for key, typename in keys_and_typenames:
      R[ key ] = value = row[ key ]
      if value is not None and typename in ( 'json', 'jsonb', ):
        R[ key ] = JSON.loads( value )
  #.........................................................................................................
  return JSON.dumps( R ) $$;
reset role;


-- =========================================================================================================
-- ARRAYS
-- ---------------------------------------------------------------------------------------------------------
-- /* thx to https://stackoverflow.com/a/8142998/7568091 */
-- create function U.unnest_2d_1d( anyarray ) returns setof anyarray immutable strict language sql as $$
--   select
--       array_agg( $1[ d1 ][ d2 ] )
--   from
--     generate_subscripts( $1, 1 ) as d1,
--     generate_subscripts( $1, 2 ) as d2
--   group by d1
--   order by d1; $$;

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://stackoverflow.com/a/8142998/7568091
  https://stackoverflow.com/a/41405177/7568091 */
create function U.unnest_2d_1d( anyarray, out a anyarray )
  returns setof anyarray immutable strict language plpgsql as $$
  begin
    foreach a slice 1 in array $1 loop
      return next;
      end loop;
    end $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- create function U.filter_array( ¶array anyarray, ¶value anyelement )
--   returns anyarray immutable language sql as $$
--   select array_agg( x ) from unnest( ¶array ) as x where x is distinct from ¶value; $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.assign( ¶a jsonb, ¶b jsonb ) returns jsonb immutable language plpgsql as $$
  begin
    if jsonb_typeof( ¶a ) != 'object' then raise exception 'expected a JSONb object, got %', ¶a; end if;
    if jsonb_typeof( ¶b ) != 'object' then raise exception 'expected a JSONb object, got %', ¶b; end if;
    return ¶a || ¶b; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.assign( ¶a jsonb, ¶b jsonb, variadic ¶tail jsonb[] )
  returns jsonb immutable language plpgsql as $$
  declare
    R         jsonb;
    ¶element  jsonb;
  begin
    R := U.assign( ¶a, ¶b );
    foreach ¶element in array ¶tail loop
      R := U.assign( R, ¶element );
      end loop;
    return R; end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://stackoverflow.com/a/12870458/7568091 */
create function U.array_sort( anyarray ) returns anyarray immutable strict language sql as $$
  select array( select unnest( $1 ) order by 1 ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.array_unique( anyarray ) returns anyarray immutable strict language sql as $$
  select array( select distinct unnest( $1 ) ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.array_sort_unique( anyarray ) returns anyarray immutable strict language sql as $$
  select array( select distinct unnest( $1 ) order by 1 ); $$;

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://dba.stackexchange.com/a/211502/126933, https://stackoverflow.com/a/42399297/7568091 */
create function U.array_unique_stable( anyarray )
  returns anyarray immutable strict parallel safe language sql as $$
  select array_agg( value order by nr )
  from ( select distinct on ( value ) value, nr
    from unnest( $1 ) with ordinality as x ( value, nr )
    order by value, nr ) as v1; $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.is_strict_subarray( anyarray, anyarray )
  returns boolean immutable strict parallel safe language sql as $$
  select true
    and array_length( $2, 1 ) > array_length( $1, 1 )
    and $2[ 1 : array_length( $1, 1 ) ] = $1; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.is_strict_subarray( anyarray, anyarray ) is 'Returns whether second
  array given is both longer than the first and starts with the same elements as the first.';

-- ---------------------------------------------------------------------------------------------------------
create or replace function U.array_regex_position( ¶texts text[], ¶regex text )
  returns bigint immutable parallel safe language sql as $$
    select nr from unnest( ¶texts ) with ordinality x ( d, nr )
    where d ~ ¶regex order by nr limit 1; $$;

comment on function U.array_regex_position( text[], text ) is 'Postgres has `array_position( a, v )` to
locate the first occurrence of a value `v` in an array `a`; `U.array_regex_position( a text[], pattern text
)` does the same, but returns the first index of array `a` that matches the regular expression `pattern`.';

-- ---------------------------------------------------------------------------------------------------------
create or replace function U.any_matches( ¶texts text[], ¶regex text )
  returns boolean immutable parallel safe language sql as $$
    select U.array_regex_position( ¶texts, ¶regex ) is not null; $$;

comment on function U.any_matches( text[], text ) is 'Same as `U.array_regex_position( a text[], pattern
text )` but just returns whether `pattern` matches any element of `a`.';

-- ---------------------------------------------------------------------------------------------------------
create function U.sets_are_equal( anyarray, anyarray )
  returns boolean immutable strict parallel safe language sql as $$
  select $1 <@ $2 and $1 @> $2; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.sets_are_equal( anyarray, anyarray ) is 'Test whether two arrays contain the
  same set of elements; return true even if some elements are reduplicated.';

-- ---------------------------------------------------------------------------------------------------------
create function U.sets_are_strictly_equal( anyarray, anyarray )
  returns boolean immutable strict parallel safe language sql as $$
  select array_length( $1, 1 ) = array_length( $2, 1 ) and $1 <@ $2 and $1 @> $2; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.sets_are_strictly_equal( anyarray, anyarray ) is 'Test whether two arrays contain
  the same set of elements; return false when the arrays differ in length.';

-- ---------------------------------------------------------------------------------------------------------
create function U.length_of( anyarray )
  returns integer immutable strict parallel safe language sql as $$
  select coalesce( array_length( $1, 1 ), 0 ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function U.length_of( text )
  returns integer immutable strict parallel safe language sql as $$
  select character_length( $1 ); $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.length_of( anyarray ) is 'Equivalent to `array_length( x, 1 )`
  but returns zero, not SQL `null` when array is empty; returns `null` on `null` input.';

-- ---------------------------------------------------------------------------------------------------------
comment on function U.length_of( text ) is 'Equivalent to `character_length( x )`.
  Returns zero, not SQL `null` when string is empty; returns `null` on `null` input.';

-- ---------------------------------------------------------------------------------------------------------
create function U.choose_coalescent( anyarray, text[] )
  returns text immutable strict parallel safe language plpgsql as $$
  begin
    for i in 1 .. U.length_of( $1 ) loop
      if ( $1[ i ] is not null ) or ( $1[ i ] is distinct from null ) then
        return $2[ i ];
        end if;
      end loop;
    return null;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.choose_coalescent( anyarray, text[] ) is 'Try to find the first non-null element in
  the first array and return the value with the same index from the second one. The first array may be of
  any type; the result will be a text.';

-- ---------------------------------------------------------------------------------------------------------
create function U.choose_coalescent( anyarray, integer[] )
  returns integer immutable strict parallel safe language sql as $$
  select ( U.choose_coalescent( $1, $2::text[] ) )::integer; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.choose_coalescent( anyarray, integer[] ) is 'Try to find the first non-null element in
  the first array and return the value with the same index from the second one. The first array may be of
  any type; the result will be an integer.';

-- select U.choose_coalescent( array[ 1, null, 2, 3 ]::integer[], '{a,b,c,d}'::text[] );
-- select U.choose_coalescent( array[ null, 1, 2, 3 ]::integer[], '{a,b,c,d}'::text[] );
-- select U.choose_coalescent( array[ null, 'a', 'b', 'c' ]::text[], '{1,2,3,4}'::integer[] );

-- ---------------------------------------------------------------------------------------------------------
-- thx to https://stackoverflow.com/a/4565551/7568091
create function U.random_word( ¶length int ) returns text volatile parallel safe language sql as $$
  select array_to_string( array( select chr( ( 97 + round( random() * 25 ) ):: integer )
    from generate_series( 1, ¶length ) ), ''); $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function U.random_word( integer ) is 'Return a random string of `n` letters chosen from `[a-z]`.';

\quit

