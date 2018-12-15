

<!-- ![](https://github.com/loveencounterflow/intershop/raw/master/artwork/intershop-logo.svg) -->

# InterShop

An incipient application basework built with SQL in PostGreSQL.

## Installation

### Dependencies

#### PostGreSQL


https://wiki.postgresql.org/wiki/Apt

```bash
sudo apt install wget ca-certificates psmisc
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
```

```sh
sudo apt install postgresql-10
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

```sh
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

#### pgsql-fio

```bash
sudo apt install postgresql-server-dev-10
git clone https://github.com/csimsek/pgsql-fio/
cd pgsql-fio
sudo make install
```

(May want to use `which pg_config` and enter the result in `Makefile` under `PG_CONFIG`)


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

#### Peru

[Peru](https://github.com/buildinspace/peru) is "a tool for including other
people's code in your projects"; it is the most convenient and promising way
I've yet found to compose one application by drawing together from various
sources crossing languages and access methods. It can be conveniently installed
via the [Peru PPA](https://launchpad.net/%7Ebuildinspace/+archive/ubuntu/peru):

```sh
sudo add-apt-repository ppa:buildinspace/peru
sudo apt update
sudo apt install peru
```



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

# The MIRAGE File Mirror Module

The [*Mirage*
module](https://github.com/loveencounterflow/intershop/blob/master/db/035-mirage.sql)
is responsible for handling all read-only linewise file access. Have a look at
[the
docs](https://github.com/loveencounterflow/intershop/blob/master/documentation/mirage.md)
and [the
demo](https://github.com/loveencounterflow/intershop/blob/master/db/demos/read-files-with-mirage.sql).
