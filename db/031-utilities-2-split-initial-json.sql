
/*

888     888
888     888
888     888
888     888
888     888
888     888
Y88b. .d88P
 "Y88888P"


*/

-- ---------------------------------------------------------------------------------------------------------
set role dba;
create function U.split_initial_json( source_ text )
  returns text[] immutable strict parallel safe language plpython3u as $$
  if len( source_ ) == 0 or source_.isspace(): return [ '', source_, ]
  #.........................................................................................................
  import json as JSON
  try:
    JSON.loads( source_ )
  except JSON.decoder.JSONDecodeError as error:
    col = error.colno - 1
    if col == 0: return [ '', source_, ]
    head  = source_[      : col ]
    tail  = source_[ col  :     ]
    if len( head ) == 0: return [ '', tail, ]
    if not head.isspace(): JSON.loads( head ) # validate this is indeed valid JSON
    return [ head, tail, ]
  return [ source_, '', ]
  $$;

comment on function U.split_initial_json( text ) is 'Given a text that may or may not start with a JSON
literal, return an array `[ head, tail, ]` where `head` contains the text of the JSON literal and `tail`
contains the rest of the string.';
reset role;

-- ---------------------------------------------------------------------------------------------------------
create function U.split_initial_json_trimmed( ¶source text )
  returns text[] immutable strict parallel safe language sql as $$
  select case head
      when '' then  array[ null, trim( both from headtail[ 2 ] ) ]
      else          array[ head, trim( both from headtail[ 2 ] ) ] end
    from
      lateral U.split_initial_json( ¶source ) as x1 ( headtail ),
      lateral trim( both from headtail[ 1 ] ) as x2 ( head ); $$;

comment on function U.split_initial_json_trimmed( text ) is 'Like `split_initial_json()`, but `head` and `tail`
will be trimmed from leading and trailing whitespace; in addition, when `head` is the empty string after
trimming, it will be set to `null` instead.';

\quit

Should be converted to tests:

select U.split_initial_json( 'true'                     ), U.split_initial_json_trimmed( 'true'                     );
select U.split_initial_json( 'truebutsomewhathidden'    ), U.split_initial_json_trimmed( 'truebutsomewhathidden'    );
select U.split_initial_json( 'null'                     ), U.split_initial_json_trimmed( 'null'                     );
select U.split_initial_json( 'nullifiable'              ), U.split_initial_json_trimmed( 'nullifiable'              );
select U.split_initial_json( '42'                       ), U.split_initial_json_trimmed( '42'                       );
select U.split_initial_json( '  42e'                    ), U.split_initial_json_trimmed( '  42e'                    );
select U.split_initial_json( '  42e10    '              ), U.split_initial_json_trimmed( '  42e10    '              );
select U.split_initial_json( '  3.  '                   ), U.split_initial_json_trimmed( '  3.  '                   );
select U.split_initial_json( '  3.1  '                  ), U.split_initial_json_trimmed( '  3.1  '                  );
select U.split_initial_json( '  0.1  '                  ), U.split_initial_json_trimmed( '  0.1  '                  );
select U.split_initial_json( '0xff  '                   ), U.split_initial_json_trimmed( '0xff  '                   );
select U.split_initial_json( 'nothing'                  ), U.split_initial_json_trimmed( 'nothing'                  );
select U.split_initial_json( '0y'                       ), U.split_initial_json_trimmed( '0y'                       );
select U.split_initial_json( '{"a":41,"b":44}'          ), U.split_initial_json_trimmed( '{"a":41,"b":44}'          );
select U.split_initial_json( '{"a":42,"b":44} '         ), U.split_initial_json_trimmed( '{"a":42,"b":44} '         );
select U.split_initial_json( '{"a":43,"b":44}["what"]'  ), U.split_initial_json_trimmed( '{"a":43,"b":44}["what"]'  );
select U.split_initial_json( '{"a":44,"b":44}   --'     ), U.split_initial_json_trimmed( '{"a":44,"b":44}   --'     );
select U.split_initial_json( '        '                 ), U.split_initial_json_trimmed( '        '                 );
select U.split_initial_json( ''                         ), U.split_initial_json_trimmed( ''                         );
select U.split_initial_json( '  .1  '                   ), U.split_initial_json_trimmed( '  .1  '                   );


