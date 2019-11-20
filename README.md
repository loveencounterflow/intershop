

<!-- ![](https://github.com/loveencounterflow/intershop/raw/master/artwork/intershop-logo.svg) -->

# InterShop

An incipient application basework built with SQL in Postgres.

# Installation

## Dependencies

### Postgres


https://wiki.postgresql.org/wiki/Apt

```bash
sudo apt install wget ca-certificates psmisc
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
```

```bash
# sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main 11" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt install postgresql-11
sudo apt install postgresql-server-dev-11
sudo apt install postgresql-plpython3-11
sudo apt install postgresql-contrib-11
sudo apt install postgresql-11-plsh
sudo apt install postgresql-11-unit
# sudo apt install postgresql-11-pgtap
# sudo apt install postgresql-11-pldebugger
# sudo apt install postgresql-9.6-plv8
# sudo apt install postgresql-plperl-9.6
```

#### Statement-Level Statistics

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

### Peru

[Peru](https://github.com/buildinspace/peru) is "a tool for including other
people's code in your projects"; it is the most convenient and promising way
I've yet found to compose one application by drawing together from various
sources crossing languages and access methods. It can be conveniently installed
via the [Peru PPA](https://launchpad.net/%7Ebuildinspace/+archive/ubuntu/peru):

```bash
sudo add-apt-repository ppa:buildinspace/peru
sudo apt update
sudo apt install peru
```

### Python

```bash
sudo pip install pipenv
pipenv install tap.py pytest
```


### InterShop

To get started with your app, create a directory for it and `cd` into it; then, copy the three essential
configuration files using `wget` (`curl` works similar):

```bash
mkdir myapp
cd myapp
wget https://raw.githubusercontent.com/loveencounterflow/intershop/master/copy-to-host-app/rakefile
wget https://raw.githubusercontent.com/loveencounterflow/intershop/master/copy-to-host-app/peru.yaml
wget https://raw.githubusercontent.com/loveencounterflow/intershop/master/intershop.ptv
```

If you don't already have a `.gitignore` file, you may want to copy (or merge) the one from InterShop; this
is to make sure your git repo won't version a gazillion dependencies under `node_modules` (although for some
use cases this is actually the recommended way):

```bash
wget https://raw.githubusercontent.com/loveencounterflow/intershop/master/.gitignore
```

Edit `intershop.ptv` so the line `intershop/host/name` spells out the name of your app (let's call it
`myapp` here), which will also become the name of the database and the Postgres user:

```ptv
intershop/host/name                             ::text=               myapp
intershop/db/port                               ::integer=            5432
intershop/db/name                               ::text=               ${intershop/host/name}
intershop/db/user                               ::text=               ${intershop/host/name}
intershop/rpc/port                              ::integer=            23001
intershop/rpc/host                              ::text/ip-address=    127.0.0.1
```

You are now ready to start installation: `peru sync` will pull the latest InterShop sources; `rake
intershop_npm_install` will run `npm install` inside the newly established `intershop` folder, and
`intershop rebuild` will create a Postgres DB (named `myapp` or whatever name you chose) and a user by the
same name and run all the `*.sql` files in `intershop/db`:

```bash
peru sync
rake intershop_npm_install
intershop rebuild
```

To get an idea what we have by now, take a gander at the catalog:

```bash
intershop psql -c "select * from CATALOG.catalog order by schema, name;"
```

The `intershop psql` invocation is essentially nothing but `psql -U $intershop_db_user -d $intershop_db_name
-p $intershop_db_port ... "@$"` where `...` denotes a bunch of configuration values.

It's probably a good idea to add your configuration to git:

```bash
git add intershop.ptv && git commit -m'add intershop.ptv'
git add peru.yaml && git commit -m'update by peru'
```

Whether or not to add the `intershop` submodule to git is a matter of taste:

```bash
git add intershop && git commit -m'updates from upstream'
```


#### Using PTV Configuration Variables in SQL

Later on, you may want to add your own options into `intershop.ptv` so you can access those configuration
settings from SQL; it's customary to prefix those options with the name of your app (but anything will work
so long as names don't start with `intershop`):

```ptv
myapp/fudge/use                                 ::boolean=          true
myapp/fudge/factor                              ::float=            3.14
myapp/fudge/delta                               ::integer=          12
```

The type annotations are currently not documented and not used programmatically; they serve at present
merely as a handy reference for the type casting one has to perform explicitly when retrieving values; so,
in your SQL you might want to do this:

```sql
select ¶( 'myapp/fudge/use'    )::boolean;
select ¶( 'myapp/fudge/factor' )::float;
select ¶( 'myapp/fudge/delta'  )::integer;
```

Variables can be used as compilation parameters:

```sql
do $$ begin
  if ¶( 'myapp/fudge/use' )::boolean then
    create function ...;
  else
    create function ...;
    end if;
  $$
```



## Running Tests

```bash
py.test --tap-files
```

# The FlowMatic Finite Automaton

see [documentation/flowmatic-fa.md](documentation/no-more-fdws-ftw.md)

# No More FDWs FTW

see [documentation/no-more-fdws-ftw.md](documentation/no-more-fdws-ftw.md)

# The MIRAGE File Mirror Module

The [*Mirage*
module](https://github.com/loveencounterflow/intershop/blob/master/db/035-mirage.sql)
is responsible for handling all read-only linewise file access. Have a look at
[the
docs](https://github.com/loveencounterflow/intershop/blob/master/documentation/mirage.md)
and [the
demo](https://github.com/loveencounterflow/intershop/blob/master/db/demos/read-files-with-mirage.sql).
