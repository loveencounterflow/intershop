

/*

 .d8888b. 8888888 8888888888 888     888 8888888888
d88P  Y88b  888   888        888     888 888
Y88b.       888   888        888     888 888
 "Y888b.    888   8888888    Y88b   d88P 8888888
    "Y88b.  888   888         Y88b d88P  888
      "888  888   888          Y88o88P   888
Y88b  d88P  888   888           Y888P    888
 "Y8888P" 8888888 8888888888     Y8P     8888888888


SIEVE is a small collection of types and functions to provide easy-to-use, fast
random sampling capabilities. A usage example is to be found in `db/tests/055-sieve.test.sql`.

Prepare the data by selecting one or more columns to derive the fingerprint from;
any kind of text input is acceptable. The column to hold the fingerprint must be
declared as `bit(68)`.

To obtain a random sample of the tbale data, you need a sieve which is a combination
of a bit mask (the 'stencil') and a random collection of bits (the 'pattern'). A
sieve may be obtained by either calling `SIEVE.new_sieve( n )` where `n` is the
number of bits to match, or else `SIEVE.new_big_sieve( sample, total )` or
`SIEVE.new_small_sieve( sample, total )? where `sample` is the number of rows you
want to filter for and `total` is the overall rowcount. The difference between
the latter two functions is connected to the fact that we can only match an integer
number of bits in a bit pattern; a 'big' sieve will tend to match more rows, a
'small' sieve will tend to match fewer rows.

You can then use the function `SIEVE.is_matching( probe, sieve )` (where `probe` is the
fingerprint of the current row) to decide whether or not to include a given row.

```
-- ---------------------------------------------------------------------------------------------------------
create materialized view _SIEVE_.some_numbers as ( select
  n                             as n,
  SIEVE.fingerprint( n::text )  as fingerprint
  from generate_series( 10000, 19999 ) as n );

-- ---------------------------------------------------------------------------------------------------------
with sieve as ( select * from SIEVE.new_small_sieve( 20, 10000 ) )
select
    n                             as n,
    fingerprint                   as fingerprint
  from
    _SIEVE_.some_numbers,
    sieve
  where SIEVE.is_matching( fingerprint, sieve )
  order by random();
```

*/


-- -- ---------------------------------------------------------------------------------------------------------
create schema SIEVE;

-- ---------------------------------------------------------------------------------------------------------
create type SIEVE.sieve as (
  stencil   bit(68),
  pattern   bit(68) );

-- ---------------------------------------------------------------------------------------------------------
/* Type for content hashes: */
create domain SIEVE.content_hash as
  character( 17 ) check ( value ~ '^[0-9a-f]{17}$' );

-- ---------------------------------------------------------------------------------------------------------
comment on domain SIEVE.content_hash is
  'type for content hashes (currently: leading 17 lower case hex digits of SHA1 hash digest)';

-- ---------------------------------------------------------------------------------------------------------
create function SIEVE.ch_from_text( text )
  returns SIEVE.content_hash language sql immutable strict as $$
  select (
    substring(
      encode(
        _pgcrypto.digest( $1::bytea, 'sha1' ),
        'hex' )
      from 1 for 17 )
    )::SIEVE.content_hash; $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function SIEVE.ch_from_text( text ) is 'Currently a duplicate of MIRAGE.ch_from_text(), this
  function returns a 17-digit lower case hexadecimal sha1sum for its input. Used by `SIEVE.fingerprint()`';

-- ---------------------------------------------------------------------------------------------------------
create function SIEVE.new_sieve( ¶bitcount integer ) returns SIEVE.sieve volatile language plpgsql as $$
  declare
    ¶stencil  bit(68);
    ¶pattern  bit(68);
  begin
    /* ### TAINT consider to use domain */
    if ¶bitcount not between 0 and 68 then
      raise exception 'expected a number between 0 and 68 as bitcount, got %', ¶bitcount;
      end if;
    ¶stencil     :=  lpad(
      substring( '11111111111111111111111111111111111111111111111111111111111111111111' from 1 for ¶bitcount ),
      68, '0' )::bit(68);
    ¶pattern  :=  SIEVE.fingerprint( random()::text ) & ¶stencil;
    return ( ¶stencil, ¶pattern );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function SIEVE.new_small_sieve( ¶sample integer, ¶total integer ) returns SIEVE.sieve volatile language sql as $$
  select SIEVE.new_sieve( ( ceil( ln( ¶total::float / ¶sample ) ) / ln( 2 ) )::integer ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function SIEVE.new_big_sieve( ¶sample integer, ¶total integer ) returns SIEVE.sieve volatile language sql as $$
  select SIEVE.new_sieve( ( floor( ln( ¶total::float / ¶sample ) ) / ln( 2 ) )::integer ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function SIEVE.is_matching( ¶probe bit(68), ¶sieve SIEVE.sieve ) returns boolean immutable language sql as $$
  select ( ¶probe & ¶sieve.stencil ) # ¶sieve.pattern = 0::bit(68); $$;

-- ---------------------------------------------------------------------------------------------------------
create function SIEVE.fingerprint( text ) returns bit(68) immutable strict language sql as $$
  select ( 'x' || SIEVE.ch_from_text( $1 ) )::bit(68); $$;

-- ---------------------------------------------------------------------------------------------------------
comment on function SIEVE.fingerprint( text ) is 'Given a text, return a 68-digit bitstring representing the
  the string''s content hash (which in turn is given by the leftmost 17 digits of the hexadecimal `sha1sum`
  over the text). Useful for quasi-random ordering, selection of items.';


