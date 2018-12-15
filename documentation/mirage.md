
## MIRAGE

```

——————————————————————————————————————————————————————————————
ooo        ooooo  o8o
`88.       .888'  `"'
 888b     d'888  oooo  oooo d8b  .oooo.    .oooooooo  .ooooo.
 8 Y88. .P  888  `888  `888""8P `P  )88b  888' `88b  d88' `88b
 8  `888'   888   888   888      .oP"888  888   888  888ooo888
 8    Y     888   888   888     d8(  888  `88bod8P'  888    .o
o8o        o888o o888o d888b    `Y888""8o `8oooooo.  `Y8bod8P'
————————————————————————————————————————— d"     YD ——————————
---        ----- ----- -----    --------- ---------  ---------
 -    -     ---   ---   ---     ---  ---  ---------  ---    --
 -  -----   ---   ---   ---      -------  ---   ---  ---------
 - ---- --  ---  ----  -------- --  ----  ---- ----  ---- ----
 ----     -----  ----  ---- ---  ------    ---------  -------
----       -----  ---
---        -----  ---
```

To announce a datasource, call `MIRAGE.procure_dsk_pathmode()` (yes, this is a
strange name that may change in the future); again, returns number of data
sources affected; a no-op if that DSK already existed with that combo of path
and mode (i.e. format):

```
select MIRAGE.procure_dsk_pathmode(
  'demo1',                                           -- Data Source Key, read dis-kee
  ¶format( '%s/README.md', 'intershop/guest/path' ), -- file path, use literal or config values
  'plain' );                                         -- file format, 'plain' is 'just text, no fields'
```

It is always necessary to explicitly refresh a MIRAGE datasource. NB that this
will perform a `sha1sum` against the file and otherwise do nothing if file
contents are up-to-date in the DB. Otherwise—if the DSK is new or file contents
have changed, it will update `MIRAGE.cache`:

```
select MIRAGE.refresh( 'demo1' );
```

One can also refresh all currently known datasources by calling
`MIRAGE.refresh()` without arguments.

After procuring and refreshing a Mirage DSK, we're now ready to access file
contents via `MIRAGE.mirror`. We filter by DSK and order, essentially, by line
numbers. The `order by dsk, dsnr, linenr` is just there to cover cases where
you have (1) filtered for more than one DSK; (2) a given DSK consists of more
than a single file (yes, that's possible):

```
select
    *
  from MIRAGE.mirror
  where dsk = 'demo1'
  order by dsk, dsnr, linenr;
```

To remove a datasource, call `MIRAGE.delete_dsk()`; returns number of data
sources deleted (you will probably not normally do this).

```
select MIRAGE.delete_dsk( 'demo1' );
```


