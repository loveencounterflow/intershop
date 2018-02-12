

# InterShop

An incipient application basework built with SQL in PostGreSQL.

## Installation

### Dependencies

#### PostGreSQL

```sh
sudo apt install postgresql-server-dev-10
sudo apt install postgresql-plpython3-10
sudo apt install postgresql-contrib-10
sudo apt install postgresql-10-plsh
sudo apt install postgresql-10-unit
# sudo apt install postgresql-10-pgtap
# sudo apt install postgresql-10-pldebugger
# sudo apt install postgresql-9.6-plv8
# sudo apt install postgresql-plperl-9.6
```

##### Statement-Level Statistics

In `postgresql.conf`:

```
shared_preload_libraries = 'pg_stat_statements'     # (change requires restart)
```

(must restart with `sudo /etc/init.d/postgresql restart 10` or similar after change; note that errors
in this settings might not lead to visible error messages, but still prevent the server from restarting).

Otherwise, comment this out in `020-extensions.sql`:

```
create extension if not exists pg_stat_statements;
```

Also see [here](https://pganalyze.com/docs/install/01_enabling_pg_stat_statements).

#### Python

```sh
sudo pip install pipenv
pipenv install tap.py pytest
```

### Running Tests

```sh
py.test --tap-files
```

# The FlowMatic Finite Automaton

see [documentation/flowmatic-fa.md](documentation/no-more-fdws-ftw.md)

# No More FDWs FTW

see [documentation/no-more-fdws-ftw.md](documentation/no-more-fdws-ftw.md)

