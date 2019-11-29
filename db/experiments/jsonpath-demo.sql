
/* ###################################################################################################### */
\ir './start.test.sql'
\timing off
-- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade;
-- \ir '../200-setup.sql'
\set filename jsonpath-demo.sql
\pset pager on

drop schema if exists X cascade;
create schema X;


create table x.characters (data jsonb);
-- insert into x.characters values ( '{
--   "name" : "Yksdargortso",
--   "id" : 1,
--   "sex" : "male",
--   "hp" : 300,
--   "level" : 10,
--   "class" : "warrior",
--   "equipment" :
--    {
--      "rings" : [
--        { "name" : "ring of despair",
--          "weight" : 0.1
--        },
--        {"name" : "ring of strength",
--         "weight" : 2.4
--        }
--      ],
--      "arm_right" : "Sword of flame",
--      "arm_left" : "Shield of faith"
--    }
--   }');
insert into x.characters values ( $$ [ 3, 5, 7 ] $$ );
insert into x.characters values ( $$ [ 3.1, 5.4, 7.9 ] $$ );
insert into x.characters values ( $$ { "temp": 20, "wind": 80 } $$ );
insert into x.characters values ( $$ { "temp": 16, "wind": 30 } $$ );
-- insert into x.characters values ( $$ [ 3, [ 5, 7 ] ] $$ );
-- insert into x.characters values ( $$ [ 3, 5, { "a": "Alpha" } ] $$ );

-- create operator ~~ (
--   leftarg     = jsonb,
--   rightarg    = jsonpath,
--   function    = jsonb_path_query,
--   -- commutator  = ===,
--   negator     = !~~
--   -- restrict    = area_restriction_function,
--   -- join        = area_join_function,
--   -- hashes, merges
-- );

-- select * from x.characters;
-- select data, jsonb_path_query( data, '$.name' ) from x.characters;
-- select data, jsonb_path_query( data, '$' ) from x.characters;
-- select data, jsonb_path_query( data, '$.**' ) from x.characters;
-- select data, jsonb_path_query( data, '$[ 2 ].**' ) from x.characters;
-- select data, jsonb_path_query( data, '$[ 2 ]' ) from x.characters;
-- select data, jsonb_path_query( data, '$[ * ]' ) from x.characters;
-- select data, jsonb_path_query( data, '$[ * ].floor()' ) from x.characters;
-- select data, jsonb_path_query( data, '$.size()' ) from x.characters;
\echo :reverse:steel '$.*' :reset
select data, jsonb_path_query( data, '$.*' ) from x.characters;
\echo :reverse:steel '$.size()' :reset
select data, jsonb_path_query( data, '$.size()' ) from x.characters;
\echo :reverse:steel '$[ * ] ? ( @ > 5 )' :reset
select data, jsonb_path_query( data, '$[ * ] ? ( @ > 5 )' ) from x.characters;
\echo :reverse:steel '$ ? ( @ > 5 )' :reset
select data, jsonb_path_query( data, '$ ? ( @ > 5 )' ) from x.characters;
\echo :reverse:steel '- $ ? ( @ > 5 )' :reset
select data, jsonb_path_query( data, '- $ ? ( @ > 5 )' ) from x.characters;
\echo :reverse:steel '$.* ? ( @ > 5 )' :reset
select data, jsonb_path_query( data, '$.* ? ( @ > 5 )' ) from x.characters;
\echo :reverse:steel 'strict $.temp >= 20' :reset
select data, jsonb_path_query( data, 'strict $.temp >= 20' ) from x.characters;
\echo :reverse:steel 'lax $.temp >= 20' :reset
select data, jsonb_path_query( data, 'lax $.temp >= 20' ) from x.characters;
-- \echo :reverse:steel '$.keyvalue()' :reset
-- select data, jsonb_path_query( data, '$.keyvalue()' ) from x.characters;

\echo :reverse:steel select jsonb_path_exists('{"a":[1,2,3,4,5]}', '$.a[*] ? (@ >= $min && @ <= $max)', '{"min":2,"max":4}'); :reset
select jsonb_path_exists('{"a":[1,2,3,4,5]}', '$.a[*] ? (@ >= $min && @ <= $max)', '{"min":2,"max":4}');
\echo :reverse:steel select jsonb_path_query('{"a":[1,2,3,4,5]}', '$.a[*] ? (@ >= $min && @ <= $max)', '{"min":2,"max":4}'); :reset
select jsonb_path_query(
  '{"a":[1,2,3,4,5]}',
  '$.a[*] ? (@ >= $min && @ <= $max)',
  '{"min":2,"max":4}');

select jsonb_path_query( '42', '$ > 40' );
select jsonb_path_query( '42', '$ < 40' );
select jsonb_path_query( '35', '30 < $ && $ < 40' );
select jsonb_path_match( '42', '$ > 40' );
select jsonb_path_match( '42', '$ < 40' );
select jsonb_path_match( '35', '30 < $ && $ < 40' );
select '{"a":[1,2,3,4,5]}'::jsonb @? '$.a[*] ? (@ > 2)';



drop schema if exists X cascade;
create schema X;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
set role dba;
/* Unfortunately we have to use Python here as I don't see how to reasonably split strings
*and keeping the parts we split on* in (plPg)SQL */
create function X.split_initial_json( source_ text )
  returns text[] immutable strict parallel safe language plpython3u as $$
  if len( source_ ) == 0 or source_.isspace(): return [ '', source_, ]
  #.........................................................................................................
  import json as JSON
  try:
    JSON.loads( source_ )
  except JSON.decoder.JSONDecodeError as error:
    col = error.colno - 1
    if col == 0: return [ '', source_, ]
    head  = source_[      : col ]
    tail  = source_[ col  :     ]
    if len( head ) == 0: return [ '', tail, ]
    if not head.isspace(): JSON.loads( head ) # validate this is indeed valid JSON
    return [ head, tail, ]
  return [ source_, '', ]
  $$;

comment on function X.split_initial_json( text ) is 'Given a text that may or may not start with a JSON
literal, return an array `[ head, tail, ]` where `head` contains the text of the JSON literal and `tail`
contains the rest of the string.';
reset role;

-- ---------------------------------------------------------------------------------------------------------
create function X.split_initial_json_trimmed( ¶source text )
  returns text[] immutable strict parallel safe language sql as $$
  select case head
      when '' then  array[ null, trim( both from headtail[ 2 ] ) ]
      else          array[ head, trim( both from headtail[ 2 ] ) ] end
    from
      lateral X.split_initial_json( ¶source ) as x1 ( headtail ),
      lateral trim( both from headtail[ 1 ] ) as x2 ( head ); $$;

comment on function X.split_initial_json_trimmed( text ) is 'Like `split_initial_json()`, but `head` and `tail`
will be trimmed from leading and trailing whitespace; in addition, when `head` is the empty string after
trimming, it will be set to `null` instead.';

select X.split_initial_json( 'true'                     ), X.split_initial_json_trimmed( 'true'                     );
select X.split_initial_json( 'truebutsomewhathidden'    ), X.split_initial_json_trimmed( 'truebutsomewhathidden'    );
select X.split_initial_json( 'null'                     ), X.split_initial_json_trimmed( 'null'                     );
select X.split_initial_json( 'nullifiable'              ), X.split_initial_json_trimmed( 'nullifiable'              );
select X.split_initial_json( '42'                       ), X.split_initial_json_trimmed( '42'                       );
select X.split_initial_json( '  42e'                    ), X.split_initial_json_trimmed( '  42e'                    );
select X.split_initial_json( '  42e10    '              ), X.split_initial_json_trimmed( '  42e10    '              );
select X.split_initial_json( '  3.  '                   ), X.split_initial_json_trimmed( '  3.  '                   );
select X.split_initial_json( '  3.1  '                  ), X.split_initial_json_trimmed( '  3.1  '                  );
select X.split_initial_json( '  0.1  '                  ), X.split_initial_json_trimmed( '  0.1  '                  );
select X.split_initial_json( '0xff  '                   ), X.split_initial_json_trimmed( '0xff  '                   );
select X.split_initial_json( 'nothing'                  ), X.split_initial_json_trimmed( 'nothing'                  );
select X.split_initial_json( '0y'                       ), X.split_initial_json_trimmed( '0y'                       );
select X.split_initial_json( '{"a":41,"b":44}'          ), X.split_initial_json_trimmed( '{"a":41,"b":44}'          );
select X.split_initial_json( '{"a":42,"b":44} '         ), X.split_initial_json_trimmed( '{"a":42,"b":44} '         );
select X.split_initial_json( '{"a":43,"b":44}["what"]'  ), X.split_initial_json_trimmed( '{"a":43,"b":44}["what"]'  );
select X.split_initial_json( '{"a":44,"b":44}   --'     ), X.split_initial_json_trimmed( '{"a":44,"b":44}   --'     );
select X.split_initial_json( '        '                 ), X.split_initial_json_trimmed( '        '                 );
select X.split_initial_json( ''                         ), X.split_initial_json_trimmed( ''                         );
select X.split_initial_json( '  .1  '                   ), X.split_initial_json_trimmed( '  .1  '                   );


/* ###################################################################################################### */
\echo :red ———{ :filename 10 }———:reset
\quit



/* ====================================================================================================== */
\ir './test-perform.sql'

\pset pager on
-- select distinct xcode from FACTORS.factors order by xcode;
-- select glyph, wbf5        from FACTORS.factors            where glyph in ( '際', '祙', '祭', '⽰', '未' );
-- select * from FACTORS._010_factors;

/* ====================================================================================================== */
\ir './test-end.sql'
\quit
