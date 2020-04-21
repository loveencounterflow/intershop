


<!-- ![](https://github.com/loveencounterflow/intershop/raw/master/artwork/intershop-logo.svg) -->

# InterShop

An incipient application foundation built on Postgres, with sprinkles of JavaScript and plPython3u

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Installation](#installation)
  - [Dependencies](#dependencies)
    - [Postgres](#postgres)
      - [Configure Postgres](#configure-postgres)
      - [Find Configuration File Locations](#find-configuration-file-locations)
      - [Statement-Level Statistics](#statement-level-statistics)
    - [Peru](#peru)
    - [Python](#python)
  - [InterShop Initialization and (Re-) Building](#intershop-initialization-and-re--building)
    - [Some Queries of Interest](#some-queries-of-interest)
    - [Using PTV Configuration Variables in SQL](#using-ptv-configuration-variables-in-sql)
- [InterShop Commands](#intershop-commands)
  - [Built-In Commands](#built-in-commands)
    - [`intershop node` and `intershop nodexh`](#intershop-node-and-intershop-nodexh)
    - [`intershop psql`](#intershop-psql)
    - [`intershop rebuild`](#intershop-rebuild)
  - [User-Defined Commands](#user-defined-commands)
- [InterShop AddOns](#intershop-addons)
  - [Format of `intershop-package.json`](#format-of-intershop-packagejson)
    - [Running Tests](#running-tests)
- [The InterShop Dev Cycle](#the-intershop-dev-cycle)
  - [Setup 1: 'Regular' InterShop setup](#setup-1-regular-intershop-setup)
  - [Setup 2: Clone InterShop from Within App Folder](#setup-2-clone-intershop-from-within-app-folder)
  - [Setup 3: Put Symlink to Local InterShop Repo into App Folder](#setup-3-put-symlink-to-local-intershop-repo-into-app-folder)
  - [Future](#future)
- [No More FDWs FTW](#no-more-fdws-ftw)
- [The MIRAGE File Mirror Module](#the-mirage-file-mirror-module)
- [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Installation

## Dependencies

### Postgres


* https://wiki.postgresql.org/wiki/Apt
* https://askubuntu.com/questions/445487/what-debian-version-are-the-different-ubuntu-versions-based-on
* https://www.linuxmint.com/download_all.php


```bash
sudo apt install wget ca-certificates psmisc
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
```

```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
```

```bash
sudo apt install postgresql-12
sudo apt install postgresql-server-dev-12
sudo apt install postgresql-plpython3-12
sudo apt install postgresql-contrib-12
sudo apt install postgresql-12-unit
sudo apt install postgresql-12-plsh
# sudo apt install postgresql-12-pgtap
# sudo apt install postgresql-12-pldebugger
# sudo apt install postgresql-9.6-plv8
# sudo apt install postgresql-plperl-9.6
```

<!--

mkdir etc.postgresql.12.main && cd etc.postgresql.12.main
sudo ln /etc/postgresql/12/main/postgresql.conf
sudo ln /etc/postgresql/12/main/pg_ident.conf
sudo ln /etc/postgresql/12/main/pg_hba.conf

 -->

#### Configure Postgres

#### Find Configuration File Locations

In the below, adjust port; the first Postgres installation will likely listen on port 5432, the next one on
port 5433 and so on; this, of course, will vary depending on whether one installed a newer PG version along
an older one and so.

```bash
sudo -u postgres psql --port 5433 -c "                                                \
  select                                                                  \
      name                                                    as key,     \
      setting                                                 as value,   \
      case setting when reset_val then '' else reset_val end  as changed  \
    from pg_settings                                                      \
    where true                                                            \
      and ( category = 'File Locations' )                                 \
      order by name;"
```

This will output a table similar to this one:

```
        key        |                  value                  | changed
-------------------+-----------------------------------------+---------
 config_file       | /etc/postgresql/12/main/postgresql.conf |
 data_directory    | /var/lib/postgresql/12/main             |
 external_pid_file | /var/run/postgresql/12-main.pid         |
 hba_file          | /etc/postgresql/12/main/pg_hba.conf     |
 ident_file        | /etc/postgresql/12/main/pg_ident.conf   |
```

Personally, I prefer to create a `git`-versioned project so I can track (and, when necessary, undo) my
changes to the PG configuration. Inside that project, I create one directory for each version and use
*hard*links (not symlinks) so I get mirrored local versions of the pertinent files that will always be
identical to the configurations as seen by Postgres.

In `pg_hba.conf`, add these lines below the one that reads

```
# Database administrative login by Unix domain socket
local   all             postgres                                peer
```

Do **not** change the above, just add these lines to indicate that connections from localhost should always
be trusted:

```
### in pg_hba.conf ###
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             localhost               trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
```
<!--
```
### in pg_ident.conf ###
# MAPNAME       SYSTEM-USERNAME         PG-USERNAME
omicron         myusername              myusername
omicron         myusername              myprojectname1
omicron         myusername              somedb
omicron         myusername              foobar
```
 -->

**You must restart Postgres after changing the configuration**, for example with one of these lines:

```bash
sudo /etc/init.d/postgresql restart ; echo $?
sudo /etc/init.d/postgresql restart 12 ; echo $?
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

A quick rundown of `peru` commands copied from [the Peru documentation]():

* **`peru sync`**—Pull in your imports. sync yells at you instead of overwriting existing or modified files.
  Use `--force`/`-f` to tell it you're serious.
* **`peru clean`**—Remove imported files. Same `--force`/`-f` flag as `sync`.
* **`peru reup`**—Update module fields with new revision information. For `git`, `hg`, and `svn`, this
  updates the `rev` field. For `curl`, this sets the `sha1` field. You can optionally give specific module
  names as arguments.
* **`peru copy`**—Make a copy of all the files in a module. Either specify a directory to put them in, or
  peru will create a temp dir for you. You can use this to see modules you don't normally import, or to play
  with different module/rule combinations (see
  [Rules](https://github.com/buildinspace/peru/blob/master/README.md#rules)).
* **`peru override`**—Replace the contents of a module with a local directory path, usually a clone you've
  made of the same repo. This lets you test changes to imported modules without needing to push your changes
  upstream or edit peru.yaml.


### Python

```bash
sudo pip install pipenv
pipenv install tap.py pytest
```


## InterShop Initialization and (Re-) Building

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

**You probably do not want to add the directories `.peru` and `intershop` to your git repo, so make sure
that both entries do appear in your `.gitignore` file.**


Edit `intershop.ptv` so the line `intershop/host/name` spells out the name of your app (let's call it
`myapp` here), which will also become the name of the database and the Postgres user:

```ptv
intershop/host/name                             ::text=               myapp
intershop/db/port                               ::integer=            5432
intershop/db/name                               ::text=               ${intershop/host/name}
intershop/db/user                               ::text=               ${intershop/host/name}
```

You are now ready to start installation: `peru sync` will pull the latest InterShop sources; `rake
intershop_npm_install` will run `npm install` inside the newly established `intershop` folder, and
`intershop rebuild` will create a Postgres DB (named `myapp` or whatever name you chose) and a user by the
same name and run all the `*.sql` files in `intershop/db`:

```bash
peru reup && peru sync
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

### Some Queries of Interest


### Using PTV Configuration Variables in SQL

In order to show a table of all current variables, run

```bash
intershop psql -c "select * from U.variables order by key;"
```

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

# InterShop Commands

## Built-In Commands

### `intershop node` and `intershop nodexh`
### `intershop psql`
### `intershop rebuild`

## User-Defined Commands

# InterShop AddOns

* first example of this: [InterShop RPC](https://github.com/loveencounterflow/intershop-rpc), a package to
  enable Inter-Process Communication (IPC), including Remote Procedure Calls (RPCs) to be executed by NodeJS
* generally, a way to extend functionalities of the DB
* may consist of
  * `*.sql` files containing table definitions and so on that should be read during DB rebuilds
  * `*.py` files that are visible to the plPython3u subsystem
  * `*.js` files to be run by NodeJS
  * other files to be ignored by the ISAO subsystem

## Format of `intershop-package.json`

* decribes what to do with the files in the package
* outermost values must be a JSON object
* with one entry `intershop-package-version` that specifies the version of the format itself; must currently
  be `1.0.0`
* another entry `"files": {...}` that describes how to treat the source files
* `files` maps from filenames (relative to package root) to purposes
* purpose may be either one of
  * `"ignore"`—do nothing; used e.g. for source files that have to be transpiled. This is the default and
    may be left out
  * `"app"`—intended for the InterShop host application; as far as InterShop is concerned, equivalent to
    `"ignore"`
  * `"support"`—will be imported by the InterShop `plpython3u` subsystem ('support' meaning 'supporting
    plPython3u library')
  * `"rebuild"`—to be executed when the DB is rebuilt from scratch with the `intershop rebuild` command
<!--   * `"redo"`—to be executed when part of the DB is redone with the `intershop redo` command (pending
    official implementation of this feature) -->
<!-- * or a list with a number of choices; currently only `["rebuild","redo"]` (in either order) is allowed -->
* `intershop-package.json` files that do not meet the above criteria will cause an error

Example:

```json
{
  "intershop-package-version": "1.0.0",
  "files": {
    "ipc.sql":                                "rebuild",
    "intershop-rpc-server-secondary.js":      "app",
    "intershop-rpc-server-secondary.coffee":  "ignore",
    "ipc.py":                                 "support"
  }
}
```



### Running Tests

```bash
py.test --tap-files
```


# The InterShop Dev Cycle

In the normal course of events where one just wants to use InterShop for the benefits it offers, it is
sufficient to just do either

* `peru reup` to update to the newest version as available on https://github.com, or
* `peru sync` to pull in either the newest version (if no current version has been pulled so far) or the
  current version (that is, make sure there are no changes in your local copy that deviate from the
  current version).

In this setup (where the `intershop` directory is essentially a clone of a remote repo), in order to
implement some new InterShop features and have them immediately available in the host app, one *could* work
inside a local copy of the remote repo, say `path/to/local/clone/of/intershop`; however, that would entail
having to push all changes to the remote prior to updating the local copy, which gets tedious very soon.


(how to use `peru override`)[https://github.com/buildinspace/peru/issues/187]

In your host app, register an 'override' for your local `intershop` repo with `peru`:

## Setup 1: 'Regular' InterShop setup

`intershop` dependency managed by peru

```bash
peru override add intershop path/to/local/clone/of/intershop
```

```bash
# ... edit some InterShop source file, then ...
cd path/to/local/clone/of/intershop                     # ... CD into intershop repo
coffee --map -o intershop_modules -c intershop_modules  # ... do whatever to build your code
cd -                                                    # ... CD back to project folder
peru sync                                               # ... make Peru pull changes from local InterShop repo
intershop refresh-mirage-datasources                    # ... issue suitable commands to see whether
intershop psql -c "select * from MIRAGE.mirror;"        #     everything works OK.
```

Putting everything on a single line:

```bash
( cd path/to/local/clone/of/intershop && coffee --map -o intershop_modules -c intershop_modules ) && peru sync && intershop refresh-mirage-datasources && intershop psql -c "select * from MIRAGE.mirror order by dsk, dsnr, linenr;"
```

## Setup 2: Clone InterShop from Within App Folder

TBW

## Setup 3: Put Symlink to Local InterShop Repo into App Folder

TBW

## Future

* drop stand-alone mode of InterShop
* make `npm install`able
* dev cycle will become standard NodeJS module dev cycle, no more `peru`

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


# To Do

* [ ] Remove npm dependency `squel`, replace by other query builder b/c of `npm audit`: `Failure to sanitize
  quotes which can lead to sql injection`, `Package: squel`, `No patch available`, see
  https://npmjs.com/advisories/575

* [ ] Better docs, esp. section with useful command lines, queries
* [ ] fix add-ons, documentation
* [ ] remove stand-alone capabilities as they are not needed (dev inside
  [hengist](https://github.com/loveencounterflow/hengist))
* [ ] document dev cycle (i.e. how to develop features in local copy w/out having to re-published for each
  change)
* [ ] make InterShop Mirage more useful by providing out-of-the-box configuration directives, default to
  updating datasources on rebuild; documentation
* [ ] replace most `bash` files with a sane language (any of JS, ?Ruby?, ?Python?)
* [ ] replace `rake`, `rakefile` with other language to get rid of Ruby?
* [ ] confusingly, `rake --tasks` does not display tasks, but dumps `intershop.ptv` configuration; `rake -P`
  (`rake ----prereqs`) does list tasks and their prerequisits, neither is not documented, nor are tasks
  documented. Observe that [Only tasks with descriptions set will appear in `rake
  -T`](https://stackoverflow.com/a/8713254/7568091)
* [ ] confusingly, `rake` ≡ `rake default` ≡ `rake update` ≡ `rake peru_update`; ideally there should only
  be 1 way to do it, so get rid of other 3 ways
* [ ] replace Peru?
* [ ] Mirage: local file paths like `./README.md` do not work although `¶( 'os/env/PWD' )` correctly points
  to local directory




