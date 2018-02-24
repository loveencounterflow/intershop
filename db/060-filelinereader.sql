
/*

8888888888 d8b 888           888      d8b                    8888888b.                         888
888        Y8P 888           888      Y8P                    888   Y88b                        888
888            888           888                             888    888                        888
8888888    888 888  .d88b.   888      888 88888b.   .d88b.   888   d88P  .d88b.   8888b.   .d88888  .d88b.  888d888
888        888 888 d8P  Y8b  888      888 888 "88b d8P  Y8b  8888888P"  d8P  Y8b     "88b d88" 888 d8P  Y8b 888P"
888        888 888 88888888  888      888 888  888 88888888  888 T88b   88888888 .d888888 888  888 88888888 888
888        888 888 Y8b.      888      888 888  888 Y8b.      888  T88b  Y8b.     888  888 Y88b 888 Y8b.     888
888        888 888  "Y8888   88888888 888 888  888  "Y8888   888   T88b  "Y8888  "Y888888  "Y88888  "Y8888  888

*/

-- ---------------------------------------------------------------------------------------------------------
create schema FILELINEREADER;

-- ---------------------------------------------------------------------------------------------------------
create function FILELINEREADER.is_comment( ¶line text ) returns boolean
  immutable strict language sql as $$
  select ¶line ~ '^\s*#'; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FILELINEREADER.is_blank( ¶line text ) returns boolean
  immutable strict language sql as $$
  select ¶line ~ '^\s*$'; $$;

-- ---------------------------------------------------------------------------------------------------------
/* convenience function; could be optimized to use single RegEx */
create function FILELINEREADER.is_comment_or_blank( ¶line text ) returns boolean
  immutable strict language sql as $$
  select FILELINEREADER.is_comment( ¶line ) or FILELINEREADER.is_blank( ¶line ); $$;

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function FILELINEREADER.read_lines( path_ text ) returns setof U.line_facet
  volatile language plpython3u as $$
  # plpy.execute( 'select U.py_init()' ); ctx = GD[ 'ctx' ]
  with open( path_, 'rb' ) as input:
    for line_idx, line in enumerate( input ):
      yield [ line_idx + 1, line.decode( 'utf-8' ).rstrip(), ]
  $$;
reset role;

-- ---------------------------------------------------------------------------------------------------------
create function FILELINEREADER.read_lines_skip( ¶path text ) returns setof U.line_facet
  volatile language sql as $$
    select * from FILELINEREADER.read_lines( ¶path ) where not FILELINEREADER.is_comment_or_blank( line ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FILELINEREADER.read_jsonbl( ¶path text ) returns setof U.jsonbl_facet
  volatile language sql as $$
  select linenr, line::jsonb as value from FILELINEREADER.read_lines( ¶path ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FILELINEREADER.read_jsonbl_skip( ¶path text ) returns setof U.jsonbl_facet
  volatile language sql as $$
  select linenr, line::jsonb as value from FILELINEREADER.read_lines_skip( ¶path ); $$;




