

# Catalog

InterShop module [`CATALOG`](../db/070-catalog.sql) aims to provide simplified ways to gain an overview over
all DB objects—tables, views, schemas, types, functions, be they defined by the system or by the user.

## API

* (function) **`CATALOG.parse_object_identifier( text )`**—Given a text with at most one unquoted dot, return fields
  `schema` (which may be `null`) and `name` containing the normalized versions of both parts as they appear
  in the system catalogs. The function will throw if either part is not a valid identifier which can be
  dealt with by double-quoting the offending part, but note that an empty string is never valid.

* (view) **`CATALOG.keywords`**—A view with all keywords of Postgres SQL dialect.

## To Do

* [ ] turn catalog into an addon
* [ ] add return types for functions in `CATALOG.catalog`
* [ ] add primary keys for tables in `CATALOG.catalog`
* [X] implement DB object name normalization (see `CATALOG.parse_object_identifier()`)
* [X] implement table of keywords (see `CATALOG.keywords`)

