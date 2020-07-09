

/*

888888 8888b    888 888     888     d8888 8888888b.  8888888        d8888 888b    888 88888888888 .d8888b.
  888   8888b   888 888     888    d88888 888   Y88b   888         d88888 8888b   888     888    d88P  Y88b
  888   88888b  888 888     888   d88P888 888    888   888        d88P888 88888b  888     888    Y88b.
  888   888Y88b 888 Y88b   d88P  d88P 888 888   d88P   888       d88P 888 888Y88b 888     888     "Y888b.
  888   888 Y88b888  Y88b d88P  d88P  888 8888888P"    888      d88P  888 888 Y88b888     888        "Y88b.
  888   888  Y88888   Y88o88P  d88P   888 888 T88b     888     d88P   888 888  Y88888     888          "888
  888   888   Y8888    Y888P  d8888888888 888  T88b    888    d8888888888 888   Y8888     888    Y88b  d88P
888888 8888    Y888     Y8P  d88P     888 888   T88b 8888888 d88P     888 888    Y888     888     "Y8888P"


The INVARIANT module simplifies the creation of sanity checks for your data. It contains a table
`INVARIANTS.violations` that is supposed to be always empty; as soon as values are inserted (and
the `intershop.ptv` variable `intershop/invariants/autovalidate` has been set to `true`), an
exception is raised. If `autovalidate` is off, the same effect may be achieved by executing

```
do $$ begin perform INVARIANTS.validate(); end; $$;
```

instead.

The `violations` table has three text columns, `module`, `title`, and `values`, which can be used to insert
a code to localize the test at hand, detail the purpose or expectation of the text, and a serialized
representation of the violated expectations.

For example, at some point in a module `FOOBAR` we may want to test whether a series of numbers does indeed
contain only odd numbers; in order to test for this condition, we can either test for even numbers and
insert all true outcomes, or else test for odd numbers and insert all false outcomes:

```
insert into INVARIANTS.violations ( select
    'FOOBAR',
    'all n are odd',
    row( r1, r2 )::text
  from generate_series( 1, 10, 3 ) as r1 ( n ),
  lateral ( select ( n::float / 2 ) = ( n::integer / 2 ) ) as r2 ( test )
  where r2.test );
```

The `generate_series` call will produce the series `(1,4,7,10)`, of which `4` and `10` are even and get
inserted into the violations table; consequently, INVARIANTS will raise an exception:

```
INVARIANTS 44644 (FOOBAR,"all n are odd","(4,""(t)"")")
INVARIANTS 44644 (FOOBAR,"all n are odd","(10,""(t)"")")
psql:db/experiments/invariants.sql:66: ERROR:  #INV01-1 Violations Detected
HINT:  see above
```

If we change `generate_series( 1, 10, 3 )` to `generate_series( 1, 10, 4 )`, everything will be fine
of course and `INVARIANTS` will just output a message that tests have performed OK.

Typically, your assertions will take an existing relation and select unexpected matches into the violations
table, like this:

```
insert into INVARIANTS.violations ( select
    'DICTIONARY', 'no entries end in a semicolon',
    r1::text
  from DICTS.mydict as r1
  where ( line ~ ';$' ) );
```

*/



/* ###################################################################################################### */
drop schema if exists INVARIANTS cascade;
create schema INVARIANTS;

-- ---------------------------------------------------------------------------------------------------------
create table INVARIANTS.tests (
    module              text    not null,
    title               text    not null,
    values              text    not null,
    is_ok               boolean default false );

-- ---------------------------------------------------------------------------------------------------------
create view INVARIANTS.violations as select
    module,
    title,
    values
  from INVARIANTS.tests
  where not coalesce( is_ok, false );

-- ---------------------------------------------------------------------------------------------------------
create function INVARIANTS.validate()
  returns void stable parallel unsafe language plpgsql as $$
  declare
    ¶row        record;
  begin
    if ( select count(*) > 0 from ( select * from INVARIANTS.violations limit 1 ) as x ) then
      perform log( '^INVARIANTS 44644^ ------------------------------------------------------------------' );
      perform log( '^INVARIANTS 44644^ output of INVARIANTS.validate():' );
      for ¶row in ( select * from INVARIANTS.violations ) loop
        perform log( '^INVARIANTS 44644^ violation:', ¶row::text );
        end loop;
      perform log( '^INVARIANTS 44644^ ------------------------------------------------------------------' );
      raise sqlstate 'INV01' using message = '#INV01-1 Violations Detected', hint = 'see above or below';
    else
      perform log( '^INVARIANTS 44645^', 'INVARIANTS.validate(): ok' );
      end if;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function INVARIANTS.on_after_insert_into_tests_row() returns trigger language plpgsql as $$
  begin
    if not new.is_ok and ¶( 'intershop/invariants/showinserts' )::boolean then
      perform log( '^INVARIANTS 44646^ violation:', new::text );
      end if;
    return new; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function INVARIANTS.on_after_insert_into_tests_statement() returns trigger language plpgsql as $$
  begin
    if ¶( 'intershop/invariants/autovalidate' )::boolean then
      perform INVARIANTS.validate();
      end if;
    return new; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create trigger on_after_insert_into_tests_row after insert on INVARIANTS.tests
  for each row execute procedure INVARIANTS.on_after_insert_into_tests_row();
create trigger on_after_insert_into_tests_statement after insert on INVARIANTS.tests
  for each statement execute procedure INVARIANTS.on_after_insert_into_tests_statement();

/* ====================================================================================================== */
\quit

