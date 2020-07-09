
/* ###################################################################################################### */
\ir './_trm.sql'
-- \ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
begin transaction;
-- \ir '../052-invariants.sql'
\set filename interplot/db/experiments/052-invariants-next-version.sql
\set signal :red
\set ECHO none


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
insert into INVARIANTS.violations values ( 'X1', 'x1', 'test1' );
insert into INVARIANTS.tests      values ( 'X2', 'x2', 'test2' );
insert into INVARIANTS.tests      values ( 'X3', 'x3', 'test3', true );
select * from INVARIANTS.violations;
select * from INVARIANTS.tests;
do $$ begin perform INVARIANTS.validate(); end; $$;


/* ###################################################################################################### */
\echo :red ———{ :filename 13 }———:reset
\quit

-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
create view INVARIANTS.all_violations as ( ( select
    module,
    title,
    values
  from INVARIANTS.violations ) union all ( select
    module,
    title,
    values
  from INVARIANTS.tests
  where not is_ok ) );

-- ---------------------------------------------------------------------------------------------------------
insert into INVARIANTS.violations ( select
    'FOOBAR',
    'all n are odd',
    row( r1.n, r2.ok )::text
  from generate_series( 1, 10, 3 ) as r1 ( n ),
  lateral ( select ( n::float / 2 ) != ( n::integer / 2 ) ) as r2 ( ok )
  where not r2.ok );

select * from INVARIANTS.violations;
-- do $$ begin perform INVARIANTS.validate(); end; $$;
select * from INVARIANTS.validate();





/* ###################################################################################################### */
\echo :red ———{ :filename 13 }———:reset
\quit

