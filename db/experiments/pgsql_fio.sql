
set role dba;
create extension if not exists fio;
select fio_readdir('/usr/', '*');



