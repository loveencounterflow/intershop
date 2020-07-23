
-- ---------------------------------------------------------------------------------------------------------
\ir './_trm.sql'
\set ON_ERROR_STOP true
\set QUIET on
\set ECHO none
\pset null '∎'
\set signal :red
\set filename intershop/custom-ordering-operators.sql

begin transaction;
drop schema if exists DEMO cascade;
create schema DEMO;
\set intershop_db_name interplot
\set intershop_db_user interplot
grant create on database :intershop_db_name to :intershop_db_user;

/*


https://www.postgresql.org/message-id/200708112214.58176.andreak@officenet.no

> regression=# create function btrevfloat8cmp(float8,float8) returns int as
> regression-# $$begin return btfloat8cmp($2, $1); end$$
> regression-# language plpgsql strict immutable;
> CREATE FUNCTION
>
> You then make the opclass using the regular comparison operators listed
> in backwards order, plus the reverse comparison function:
>
> regression=# create operator class rev_float8_ops for type float8 using
> btree regression-# as
> regression-# operator 1 > ,
> regression-# operator 2 >= ,
> regression-# operator 3 = ,
> regression-# operator 4 <= ,
> regression-# operator 5 < ,
> regression-# function 1 btrevfloat8cmp(float8,float8) ;
> CREATE OPERATOR CLASS
>
> And you're off:
>
> regression=# create table myt (f1 float8, f2 float8);
> CREATE TABLE
> regression=# create index myi on myt using btree (f1, f2 rev_float8_ops);
> CREATE INDEX
> regression=# insert into myt values(1,1),(1,2),(1,3),(2,1),(2,2),(2,3);
> INSERT 0 6
> regression=# explain select * from myt order by f1 asc, f2 desc;
> QUERY PLAN
> --------------------------------------------------------------------
> Index Scan using myi on myt (cost=0.00..72.70 rows=1630 width=16)
> (1 row)
>
> regression=# select * from myt order by f1 asc, f2 desc;
> f1 | f2
> ----+----
> 1 | 3
> 1 | 2
> 1 | 1
> 2 | 3
> 2 | 2
> 2 | 1
> (6 rows)
>
> regression=# explain select * from myt order by f1 desc, f2 asc;
> QUERY PLAN
> ---------------------------------------------------------------------------
>-- Index Scan Backward using myi on myt (cost=0.00..72.70 rows=1630
> width=16) (1 row)
>
> regression=# select * from myt order by f1 desc, f2 asc;
> f1 | f2
> ----+----
> 2 | 1
> 2 | 2
> 2 | 3
> 1 | 1
> 1 | 2
> 1 | 3
> (6 rows)
>



*/



-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
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
  p point
  );
insert into DEMO.points select point(floor(random()*100), floor(random()*100)) from generate_series(1, 5);
select * from DEMO.points order by p using >^;


-- =========================================================================================================
-- OPERATORS FOR VNRs
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
/* thx to https://stackoverflow.com/questions/7205878/order-by-using-clause-in-postgresql#7461843 */
-- set role dba;
create operator family vnr_cmp_family using btree;   -- superuser access required!
-- reset role;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create function vnr_greater_than( VNR.vnr, VNR.vnr )
  returns boolean immutable strict language plpgsql as $$
    begin return true; end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
create function vnr_equals( VNR.vnr, VNR.vnr )
  returns boolean immutable strict language plpgsql as $$
    begin return false; end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create operator < (
    leftarg     = VNR.vnr,
    rightarg    = VNR.vnr,
    function    = vnr_greater_than,
    commutator  = > );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
create operator = (
    leftarg     = VNR.vnr,
    rightarg    = VNR.vnr,
    function    = vnr_equals );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create function vnr_cmp( ¶vnr1 VNR.vnr, ¶vnr2 VNR.vnr ) returns int language plpgsql as $$
  begin
    return 1;
    end $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
create operator class vnr_cmp_ops for type VNR.vnr using btree family vnr_cmp_family as
  operator 1 >  ,
  -- operator 2 >= ,
  operator 3 =  ,
  -- operator 4 <= ,
  operator 5 <  ,
  -- function 1 vnr_cmp( VNR.vnr, VNR.vnr );
  function 1 vnr_greater_than( VNR.vnr, VNR.vnr );

-- =========================================================================================================
\echo :signal ———{ :filename 7 }———:reset
create table DEMO.vnrs (
  vnr VNR.vnr
  );
insert into DEMO.vnrs values
  ( '{0}':VNR.vnr ),
  ( '{}':VNR.vnr );


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
select * from DEMO.vnrs order by vnr;
select * from DEMO.vnrs order by vnr using >^;

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



