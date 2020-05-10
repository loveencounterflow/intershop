<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [VNRs](#vnrs)
  - [Intro](#intro)
  - [Implementation Details](#implementation-details)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## VNRs

### Intro

* as introduced in [Datom](https://github.com/loveencounterflow/datom/blob/master/VNRs.md)
* **vectors of numbers** of arbitrary length
* convenient **ordering properties**:
	* in any given sequence of VNRs with two adjacent VNRs `a`, `c`, **one can always insert one more VNR**
	  `b` such that the new VNR comes after `a` and before `c`.
	* for document processing this means that in order to represent all the records that arise from a given
	  line `n` of a source file, when one uses an `integer[]` field instead of `integer`, one can insert new
	  records with VNRs `[ n, 1, ]`, `[ n, 2, ]` etc, and these will always come before those with VNRs `[
	  n+1, ... ]` that resulted from the next line in the source
	* no renumbering is necessery for insertions or deletions
* since the change brought about by an insertion is purely local (does not affect any other element except
  the one inserted), VNRs lend themselves to implementing **write-only datastores** where
  * no records, once inserted, are ever changed (with the exception of a boolean field, call it `stamped`,
    default `false`)
  * insertions that come *after* a given row `r` with VNR `[ a, b, c, ]` are performed by adding a record
    `s` with `[ a, b, c, x, ]`; if `x` is negative, `s` will be sorted before `r`; if it is not negative,
    `s` will be sorted *after* `r`
  * updates work exactly like insertions, except that the old row has to be deprecated by setting field
  	`stamped` to `true` (like the post office stamps a letter to mark it as 'processed')
  * see InterShop schema `IMMUTABLE` for an implementation of an `on before update` trigger that makes sure
    no fields of immutable records are ever changed, except for field `stamped`, which can only go from
    `false` to `true`

### Implementation Details

* VNRs are meant to only contain integer numbers
* but in principle, nothing speaks against fractional numbers as elements
* we're using `float8` (`double precsion`) instead of `integer` arrays because we then get `Infinity` for
  free which is great to represent rows that must always keep their initial or final positions; also, this
  is essentially the same material datatype as JS (IEEE-754), so better compatibility
* users are discouraged to use fractional erlements in VNRs a la `[ 1, 4.5, 3.14159, ]`, but can be done
  where needed
* users are discouraged to use VNRs ending in zeroes like `[ 1, 1, 3, 0, ]` in numbering schemes where they
  could coexist with VNRs that are equal except for the trailing zero (`[ 1, 1, 3, ]` in this example). *In
  case the numbering scheme mandates assigning VNRs with tuples of coordinates like `[ a1, b1, a2, b2,
  ..., ]`, trailing zeroes are not special in any way, however*.
* since 'naive' sorting using `order by vnr` will only be almost, but not quite correct (because it results
  in `[ a, ] ≺ [ a, -1, ] ≺ [ a, 0, ] ≺ [ a, 1, ]` instead of the correct `[ a, -1, ] ≺ [ a, ] ≺ [ a, 0, ] ≺
  [ a, 1, ]`), we **use a generated column (conventionally called `_vnr0`)** that has the original VNR
  with a zero appended (such that `order by _vnr0` will result in `[ a, -1, 0, ] ≺ [ a, 0, ] ≺ [ a, 0, 0, ]
  ≺ [ a, 1, 0, ]`, which is OK)
* let's call the function used for the generated column `add_final_zero( vnr )`
* if preferrable, one could always forego the generated column and use the zero-appending function in an
  `order by` clause instead, as in: `order by add_final_zero( vnr )`
  * this can also be indexed: `create index on X.t ( add_final_zero( vnr ) )` to prevent re-computation on
    `select`
* another alternative to using a generated column or ordering-by-function is to define a custom operator,
  call it `<<<`, such that one can write `order by vnr using <<<`. However, this approach suffers from
	* having an annoying syntax (an unquoted operator used as a name),
	* is longer to write, but also
	* is less obvious (can't rely on givens in table, must lookup definition of `<<<`)
	* is annoyingly [hard to
	  define](https://stackoverflow.com/questions/7205878/order-by-using-clause-in-postgresql#7461843) (also
	  [db/experiments/custom-ordering-operators.sql](db/experiments/custom-ordering-operators.sql))
	* alas, no equivalent to JS `[].sort( cmp )` is available in Postgres, which I find strange given the
	  importance of sorting DB rows
	* once more, that old chestnut has proven itself to be true: **When in need of a custom ordering, do not
	  attempt to define custom collations or custom operators, instead, generate a sortfield**



