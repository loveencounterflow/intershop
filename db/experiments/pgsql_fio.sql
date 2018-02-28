

-- ---------------------------------------------------------------------------------------------------------
\pset pager on
\ir '../010-trm.sql'
\echo :cyan'——————————————————————— benchmark-pl-languages-001-setup.sql ———————————————————————':reset

set role dba;
create extension if not exists fio;
reset role;

select * from fio_readdir( '/home/flow/io/intershop', '*' );



