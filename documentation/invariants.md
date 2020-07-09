

# Invariants

The `INVARIANT` schema/module simplifies the creation of sanity checks for your data. It consists of the
following parts:

* a table `INVARIANTS.tests`:

  ```sql
  create table INVARIANTS.tests (
      module              text    not null,
      title               text    not null,
      values              text    not null,
      is_ok               boolean default false );
  ```

This is the first of two places where the user may use an `insert` statement to perform test results.
`module` and `title` are arbitrary strings to identify the test, `values` is there to hold the serialized
results of the test for later reference, and `is_ok` is a Boolean to indicate whether the test succeeded
(`true`) or failed (`false` or `null`).

* an insertable view `INVARIANTS.violations`; it has the same fields as `INVARIANTS.tests` except for the
  last field, `is_ok`, which is assumed to be `false` when inserting into `INVARIANTS.violations`.

* a function `INVARIANTS.validate()`; this function will raise an exception in case `INVARIANTS.violations`
  has any entries (i.e. when field `is_ok` of any row in `INVARIANTS.tests` is not `true`).

There are two settings in your `intershop.ptv` file that control the behavior of `INVARIANTS`:

* when `intershop/invariants/autovalidate` is `true` (the default), then any statement that inserts a failed
  test will cause an exception to be raised, accompanied with a printout of the offending rows. When
  `intershop/invariants/autovalidate` has been set to `false`, the user will have to trigger the validation
  themselves, e.g. by executing `select INVARIANTS.validate();`.

* when `intershop/invariants/showinserts` is `true` (the default), then inserting a failed test case will
  cause the data to be logged to the terminal.

## Example Usage

### Using the Tests Table

If you decide to use the `INVARIANTS.tests` table (recommended), then you will (probably) want to insert all
tests cases; this way, there will be a nice satisfactory listing of all tests run once the tests have
completed which is also useful to spot any inadvert omissions. Assuming you have a view or table with actual
results from some computation and another relation with matchers (expected results), you could insert the
rows resulting from `join`ing the two into `INVARIANTS.tests`:

```sql
insert into INVARIANTS.tests select
    'MYMODULE'                                    as module,
    'name of the test'                            as title,
    row( results, matchers )::text                as values,
    ( results.some_field = matchers.some_field )  as is_ok
  from MYMODULE.table_with_results              as results
  full outer join MYMODULE.table_with_matchers  as matchers using ( pk );
```

This setup will catch cases where there missing and/or extraneous rows in either `results` or `matchers`
because of the `full outer join` clause; it will, however, accept cases where duplicate rows are present; to
catch those, either use another test or intodruce stricter `unique`ness constraints.


### Using the Violations View

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
