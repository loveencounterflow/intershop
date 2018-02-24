
-- ---------------------------------------------------------------------------------------------------------
-- create schema TRM;

-- ---------------------------------------------------------------------------------------------------------
\set blink        '\x1b[5m'
\set bold         '\x1b[1m'
\set reverse      '\x1b[7m'
\set underline    '\x1b[4m'
\set reset        '\x1b[0m'
\set black        '\x1b[38;05;16m'
\set blue         '\x1b[38;05;27m'
\set green        '\x1b[38;05;34m'
\set cyan         '\x1b[38;05;51m'
\set sepia        '\x1b[38;05;52m'
\set indigo       '\x1b[38;05;54m'
\set steel        '\x1b[38;05;67m'
\set brown        '\x1b[38;05;94m'
\set olive        '\x1b[38;05;100m'
\set lime         '\x1b[38;05;118m'
\set red          '\x1b[38;05;124m'
\set crimson      '\x1b[38;05;161m'
\set plum         '\x1b[38;05;176m'
\set pink         '\x1b[38;05;199m'
\set orange       '\x1b[38;05;208m'
\set gold         '\x1b[38;05;214m'
\set tan          '\x1b[38;05;215m'
\set yellow       '\x1b[38;05;226m'
\set grey         '\x1b[38;05;240m'
\set darkgrey     '\x1b[38;05;234m'
\set white        '\x1b[38;05;255m'


\set O            :reset
\set TITLE        :yellow
\set Xcolor       :orange
\set OUT          :yellow'output written to ':lime
\set X            :plum
\set devnull      '/dev/null'

-- \echo :F'trm.meta.sql':O
-- \echo :X'experiments-echo-message.sql':O
-- \echo ok

-- -- ---------------------------------------------------------------------------------------------------------
-- create table TRM.colors (
--   key   text unique not null primary key,
--   value text        not null );

-- -- ---------------------------------------------------------------------------------------------------------
-- insert into TRM.colors values
--   ( 'blink',          :'blink'        ),
--   ( 'bold',           :'bold'         ),
--   ( 'reverse',        :'reverse'      ),
--   ( 'underline',      :'underline'    ),
--   ( 'reset',          :'reset'        ),
--   ( 'black',          :'black'        ),
--   ( 'blue',           :'blue'         ),
--   ( 'green',          :'green'        ),
--   ( 'cyan',           :'cyan'         ),
--   ( 'sepia',          :'sepia'        ),
--   ( 'indigo',         :'indigo'       ),
--   ( 'steel',          :'steel'        ),
--   ( 'brown',          :'brown'        ),
--   ( 'olive',          :'olive'        ),
--   ( 'lime',           :'lime'         ),
--   ( 'red',            :'red'          ),
--   ( 'crimson',        :'crimson'      ),
--   ( 'plum',           :'plum'         ),
--   ( 'pink',           :'pink'         ),
--   ( 'orange',         :'orange'       ),
--   ( 'gold',           :'gold'         ),
--   ( 'tan',            :'tan'          ),
--   ( 'yellow',         :'yellow'       ),
--   ( 'grey',           :'grey'         ),
--   ( 'darkgrey',       :'darkgrey'     ),
--   ( 'white',          :'white'        );

\quit

\echo :blue:reverse'  ':reset:blue'This is blue':reset
\echo :green:reverse'  ':reset:green'This is green':reset
\echo :cyan:reverse'  ':reset:cyan'This is cyan':reset
\echo :sepia:reverse'  ':reset:sepia'This is sepia':reset
\echo :indigo:reverse'  ':reset:indigo'This is indigo':reset
\echo :steel:reverse'  ':reset:steel'This is steel':reset
\echo :brown:reverse'  ':reset:brown'This is brown':reset
\echo :olive:reverse'  ':reset:olive'This is olive':reset
\echo :lime:reverse'  ':reset:lime'This is lime':reset
\echo :red:reverse'  ':reset:red'This is red':reset
\echo :crimson:reverse'  ':reset:crimson'This is crimson':reset
\echo :plum:reverse'  ':reset:plum'This is plum':reset
\echo :pink:reverse'  ':reset:pink'This is pink':reset
\echo :orange:reverse'  ':reset:orange'This is orange':reset
\echo :gold:reverse'  ':reset:gold'This is gold':reset
\echo :tan:reverse'  ':reset:tan'This is tan':reset
\echo :yellow:reverse'  ':reset:yellow'This is yellow':reset
\echo :grey:reverse'  ':reset:grey'This is grey':reset
\echo :darkgrey:reverse'  ':reset:darkgrey'This is darkgrey':reset
\echo :white:reverse'  ':reset:white'This is white':reset
