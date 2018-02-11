
/* ### NOTE should at any rate turn off pager, otherwise some informative intermittent select statements may
  cause the scripts to stop and wait for user input to terminate paged output:*/
\pset pager off
-- \pset tuples_only on
\set orange       '\x1b[38;05;208m'
\set yellow       '\x1b[38;05;226m'
\set reset        '\x1b[0m'
\set reverse      '\x1b[7m'
\set _O           :reset
\set _TITLE       :yellow:reverse'  ':_O:yellow' '

\echo :_TITLE'010-trm':_O                     \ir './010-trm.sql'
\echo :_TITLE'011-bar':_O                     \ir './011-bar.sql'
\echo :_TITLE'012-time':_O                    \ir './012-time.sql'
\echo :_TITLE'020-extensions':_O              \ir './020-extensions.sql'
\echo :_TITLE'025-sql':_O                     \ir './025-sql.sql'
\echo :_TITLE'030-utilities-1':_O             \ir './030-utilities-1.sql'
\echo :_TITLE'031-utilities-2-variables':_O   \ir './031-utilities-2-variables.sql'
\echo :_TITLE'050-utilities-3-py_init':_O     \ir './050-utilities-3-py_init.sql'
\echo :_TITLE'051-utilities-4-tabulate':_O    \ir './051-utilities-4-tabulate.sql'
\echo :_TITLE'060-filelinereader':_O          \ir './060-filelinereader.sql'
\echo :_TITLE'070-catalog':_O                 \ir './070-catalog.sql'
\echo :_TITLE'080-units':_O                   \ir './080-units.sql'
\echo :_TITLE'999-bye':_O                     \ir './999-bye.sql'



