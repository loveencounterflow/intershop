
-- ---------------------------------------------------------------------------------------------------------
begin transaction;
drop schema if exists DEMO cascade;
create schema DEMO;
grant create on database :intershop_db_name to :intershop_db_user;

-- ---------------------------------------------------------------------------------------------------------
-- select * from CATALOG.catalog where schema = 'pg_catalog' and name ~ 'opera';
-- select * from pg_catalog.pg_operator order by oprname;

/* thx to https://stackoverflow.com/questions/7205878/order-by-using-clause-in-postgresql#7461843 */
-- set role dba;
create operator family xyzfam using btree;   -- superuser access required!
-- reset role;

create function xyz_v_cmp( p1 point, p2 point ) returns int language plpgsql as $$
  begin return btfloat8cmp(p1[1],p2[1]); end $$;

create operator class xyz_ops for type point using btree family xyzfam as
        operator 1 <^ ,
        operator 3 ?- ,
        operator 5 >^ ,
        function 1 xyz_v_cmp(point, point);

create table DEMO.points (
  p point;
  );
insert into DEMO.points select point(floor(random()*100), floor(random()*100)) from generate_series(1, 5);
select * from DEMO.points order by p using >^;


-- -- ---------------------------------------------------------------------------------------------------------
-- create function DEMO.cmp_fair( ¶a integer[], ¶b integer[] )
--   returns boolean immutable parallel safe language plpgsql as $$
--   begin
--     perform log( '^344443^', ¶a::text, ¶b::text );
--     return true;
--   end;
--   $$;

-- -- select * from pg_catalog;

-- create operator <<< ( procedure = DEMO.cmp_fair, leftarg = integer[], rightarg = integer[] ); -- +-*/<>=~!@#%^&|`?
-- select * from DEMO.datoms order by vnr using <<<;

rollback;



