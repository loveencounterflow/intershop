

-- ---------------------------------------------------------------------------------------------------------
\pset pager on
\ir '../010-trm.sql'
\echo :cyan'——————————————————————— lua-filelinereader.sql ———————————————————————':reset

-- ---------------------------------------------------------------------------------------------------------
set role dba;
drop schema if exists pllua cascade;
create extension if not exists pllua;
reset role;

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _LUAFLR_ cascade;
create schema _LUAFLR_;

-- set role dba;
-- create function _LUAFLR_.perm( a text[] ) returns setof text[] language pllua as $$
--     _U(a, #a)
--   end
--   do
--     _U = function (a, n) -- permgen in PiL
--       if n == 0 then
--         coroutine.yield(a) -- return next SRF row
--       else
--         for i = 1, n do
--           a[n], a[i] = a[i], a[n] -- i-th element as last one
--           _U(a, n - 1) -- recurse on head
--           a[n], a[i] = a[i], a[n] -- restore i-th element
--           end
--         end
--       end $$;
-- reset role;

-- select * from _LUAFLR_.perm( array[ 'a', 'b', 'c' ] ) as permutations order by permutations;


-- create type _LUAFLR_.greeting as ( how text, who text );

-- set role dba;
-- create function _LUAFLR_.makegreeting( g _LUAFLR_.greeting, f text ) returns text language pllua as $$
--   return string.format( f, g.how, g.who )
--   $$;
-- reset role;

-- set role dba;
-- create function _LUAFLR_.greetingset( how text, who text[] ) returns setof _LUAFLR_.greeting language pllua as $$
--   for _, name in ipairs( who ) do
--     coroutine.yield{ how = how, who = name }
--     end $$;
-- reset role;

-- select _LUAFLR_.makegreeting( set_of_greetings, '%s, %s!' ) from ( select
--   _LUAFLR_.greetingset( 'hello', array[ 'foo', 'bar', 'psql' ] ) as set_of_greetings ) as q;


-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _LUAFLR_.get_version() returns text language pllua as $$
  return _VERSION
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _LUAFLR_.count_text_filelines( path text ) returns integer language plluau as $$
  -- thx to http://lua-users.org/wiki/ForTutorial
  -- input, err = io.open( path, 'r' )
  -- if err
  input = assert( io.open( path, 'r' ) )
  R = 0
  for line in input:lines() do
    R = R + 1
    -- print( line )
    end
  input:close()
  return R
  -- for _, name in ipairs( who ) do
  --   coroutine.yield{ how = how, who = name }
  -- end
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function _LUAFLR_.read_lines( path text ) returns setof U.line_facet language plluau as $$
  input = assert( io.open( path, 'r' ) )
  linenr = 0
  for line in input:lines() do
    linenr = linenr + 1
    coroutine.yield{ linenr = linenr, line = line }
    end
  input:close()
  $$;
reset role;


-- ---------------------------------------------------------------------------------------------------------
select _LUAFLR_.get_version();


-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :orange'---==( pllua )==---':reset
-- create materialized view _LUAFLR_.filelines_via_plluau as (
--   select
--       paths.path                as path,
--       lines.linenr              as linenr,
--       lines.line                as line
--     from _LUAFLR_.paths as paths,
--     lateral _LUAFLR_.read_lines( '/home/flow/io/mingkwai-rack/jzrds' || '/' || paths.path ) as lines
--       );

