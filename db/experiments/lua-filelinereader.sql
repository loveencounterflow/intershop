
set role dba;
create extension if not exists pllua;
reset role;

drop schema if exists _L_ cascade;
create schema _L_;

set role dba;
create function _L_.perm( a text[] ) returns setof text[] language pllua as $$
    _U(a, #a)
  end
  do
    _U = function (a, n) -- permgen in PiL
      if n == 0 then
        coroutine.yield(a) -- return next SRF row
      else
        for i = 1, n do
          a[n], a[i] = a[i], a[n] -- i-th element as last one
          _U(a, n - 1) -- recurse on head
          a[n], a[i] = a[i], a[n] -- restore i-th element
          end
        end
      end $$;
reset role;

select * from _L_.perm( array[ 'a', 'b', 'c' ] ) as permutations order by permutations;


create type _L_.greeting as ( how text, who text );

set role dba;
create function _L_.makegreeting( g _L_.greeting, f text ) returns text language pllua as $$
  return string.format( f, g.how, g.who )
  $$;
reset role;

set role dba;
create function _L_.greetingset( how text, who text[] ) returns setof _L_.greeting language pllua as $$
  for _, name in ipairs( who ) do
    coroutine.yield{ how = how, who = name }
    end $$;
reset role;

select _L_.makegreeting( set_of_greetings, '%s, %s!' ) from ( select
  _L_.greetingset( 'hello', array[ 'foo', 'bar', 'psql' ] ) as set_of_greetings ) as q;





