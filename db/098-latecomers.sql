

/* This file contains updates to the DB that have not yet been integrated
into their proper places; it is intended to be runnable both during a regular
rebuild as well as anytime in between and cause minimal disruption downstream;
therefore, */


/* ###################################################################################################### */
\ir './010-trm.sql'
\pset pager off
\pset tuples_only off
\timing on
-- \set ECHO queries


/* ====================================================================================================== */
\echo :red ———{ 89821 quit }———:reset
\quit



