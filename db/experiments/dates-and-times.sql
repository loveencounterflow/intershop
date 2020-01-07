

/*

88888888888  8888888  888b     d888  8888888888
    888        888    8888b   d8888  888
    888        888    88888b.d88888  888
    888        888    888Y88888P888  8888888
    888        888    888 Y888P 888  888
    888        888    888  Y8P  888  888
    888        888    888   "   888  888
    888      8888888  888       888  8888888888

*/

-- select 31557600 * 3.1415926e9;
-- \quit

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists _X_TIME cascade;
create schema _X_TIME;

-- ---------------------------------------------------------------------------------------------------------
create function _X_TIME.date_from_js_timestamp_woz( ts bigint )
  returns timestamp without time zone
  language sql
  immutable
  returns null on null input
  as $$
    -- select ( timestamp with time zone 'epoch' + ts * interval '1 millisecond' ) at time zone 'utc';
    -- select ( timestamp with time zone 'epoch' + ts * interval '1 millisecond' );
    -- select ( timestamp 'epoch' + ts * interval '1 millisecond' );
    select ( timestamp 'epoch' + ts * interval '1 millisecond' );
    $$;

-- ---------------------------------------------------------------------------------------------------------
create function _X_TIME.date_from_js_timestamp_wz( ts bigint )
  returns timestamp with time zone
  language sql
  immutable
  returns null on null input
  as $$
    -- select ( timestamp with time zone 'epoch' + ts * interval '1 millisecond' ) at time zone 'utc';
    select ( timestamp with time zone 'epoch' + ts * interval '1 millisecond' );
    -- select ( timestamp 'epoch' + ts * interval '1 millisecond' );
    -- select ( timestamp 'epoch' + ts * interval '1 millisecond' );
    $$;

-- #########################################################################################################

\pset tuples_only on

\echo ----------------------------------------------------------
\echo 'ISO'
set datestyle = 'ISO';
select _X_TIME.date_from_js_timestamp_wz( 1488821615577 );
select _X_TIME.date_from_js_timestamp_wz( 1498259910635 );

\echo ----------------------------------------------------------
\echo 'SQL'
set datestyle = 'SQL';
select _X_TIME.date_from_js_timestamp_wz( 1488821615577 );
select _X_TIME.date_from_js_timestamp_wz( 1498259910635 );

\echo ----------------------------------------------------------
\echo 'German'
set datestyle = 'German';
select _X_TIME.date_from_js_timestamp_wz( 1488821615577 );
select _X_TIME.date_from_js_timestamp_wz( 1498259910635 );

\pset tuples_only off
with
  v1 as (
    select _X_TIME.date_from_js_timestamp_wz( 1488821615577 ) as d
    ),
  v2 as (
    select d, age( clock_timestamp(), d ) as a from v1
    )
  select d, a, extract( month from a ), to_char( d, 'YYYY Mon DD HH24:MI:SS TZ' ) from v2;

select _X_TIME.date_from_js_timestamp_wz( 0 );

create function _X_TIME.interval_from_bigint( n bigint ) returns interval
language sql
as $$
  select _X_TIME.date_from_js_timestamp_wz( n ) - _X_TIME.date_from_js_timestamp_wz( 0 );
$$;


create table _X_TIME.seconds_per (
  period  text unique not null primary key,
  n       bigint );

insert into _X_TIME.seconds_per values
  ( 'year',    60 * 60 * 24     * 30.4375 * 12  ),
  ( 'month',   60 * 60 * 24     * 30.4375       ),
  ( 'week',    60 * 60 * 24 * 7                 ),
  ( 'day',     60 * 60 * 24                     ),
  ( 'hour',    60 * 60                          ),
  ( 'minute',  60                               ),
  ( 'second',  1                                );

-- select 365.25 / 12 ;
select * from _X_TIME.seconds_per;

-- select y.n, m.n, y.n / m.n
--   from
--   ( select n from _X_TIME.seconds_per where period = 'year'  ) as y,
--   ( select n from _X_TIME.seconds_per where period = 'month' ) as m;



-- ---------------------------------------------------------------------------------------------------------
create function _X_TIME.age_as_text( age_s double precision )
  returns text immutable language sql as $$
    select ''
      || case when age_s >=        31557600                then ( age_s /  31557600 )::numeric( 30, 1 )::text || ' years'   else '' end
      || case when age_s between    2629800 and   31557600 then ( age_s /   2629800 )::numeric( 30, 1 )::text || ' months'  else '' end
      || case when age_s between     604800 and    2629800 then ( age_s /    604800 )::numeric( 30, 1 )::text || ' weeks'   else '' end
      || case when age_s between      86400 and     604800 then ( age_s /     86400 )::numeric( 30, 1 )::text || ' days'    else '' end
      || case when age_s between       3600 and      86400 then ( age_s /      3600 )::numeric( 30, 1 )::text || ' hours'   else '' end
      || case when age_s between         60 and       3600 then ( age_s /        60 )::numeric( 30, 1 )::text || ' minutes' else '' end
      || case when age_s <                              60 then ( age_s /         1 )::numeric( 30, 1 )::text || ' seconds' else '' end
      ;
  $$;
-- ---------------------------------------------------------------------------------------------------------
create function _X_TIME.age_as_text( t timestamp with time zone )
  returns text immutable language sql as $$
    select _X_TIME.age_as_text( extract( epoch from clock_timestamp() - t ) ) as age
  $$;


-- ---------------------------------------------------------------------------------------------------------
create view _X_TIME.v as (
  with v1 as ( select generate_series( 1, 30 ) as e ),
  v2 as ( select e, ( 10 ^ ( e::float / 3 ) )::double precision as d from v1 )
  select
      d,
      _X_TIME.age_as_text( d )
    from v2
    order by d
  );


with v1 as ( values
  ( '2017/09/18 12:00' ),
  ( '2017/09/18' ),
  ( '2017/08/18' ),
  ( '2017/07/18' ),
  ( '2017/06/18' ),
  ( '2017/05/18' ),
  ( '2017/04/18' ),
  ( '2017/03/18' ),
  ( '2017/02/18' ),
  ( '2017/01/18' ),
  ( '2016/12/18' ),
  ( '2016/09/18' ) ),
v2 as ( select column1::timestamp with time zone as date from v1 )
select date, extract( epoch from clock_timestamp() - date ) as epoch, _X_TIME.age_as_text( date ) from v2;




create function _X_TIME.as_fields(
  in  s       bigint,
  out years   bigint,
  out months  bigint,
  out weeks   bigint,
  out days    bigint,
  out hours   bigint,
  out minutes bigint,
  out seconds bigint )
language plpgsql
as $$
  begin
    years   :=  s / ( select n from _X_TIME.seconds_per where period = 'year'   );
    months  :=  s / ( select n from _X_TIME.seconds_per where period = 'month'  );
    weeks   :=  s / ( select n from _X_TIME.seconds_per where period = 'week'   );
    days    :=  s / ( select n from _X_TIME.seconds_per where period = 'day'    );
    hours   :=  s / ( select n from _X_TIME.seconds_per where period = 'hour'   );
    minutes :=  s / ( select n from _X_TIME.seconds_per where period = 'minute' );
    seconds :=  s / ( select n from _X_TIME.seconds_per where period = 'second' );
    end; $$;

create function _X_TIME.as_fields(
  in  s       numeric,
  out years   numeric,
  out months  numeric,
  out weeks   numeric,
  out days    numeric,
  out hours   numeric,
  out minutes numeric,
  out seconds numeric )
language plpgsql
as $$
  begin
    years   :=  s / ( select n from _X_TIME.seconds_per where period = 'year'   );
    months  :=  s / ( select n from _X_TIME.seconds_per where period = 'month'  );
    weeks   :=  s / ( select n from _X_TIME.seconds_per where period = 'week'   );
    days    :=  s / ( select n from _X_TIME.seconds_per where period = 'day'    );
    hours   :=  s / ( select n from _X_TIME.seconds_per where period = 'hour'   );
    minutes :=  s / ( select n from _X_TIME.seconds_per where period = 'minute' );
    seconds :=  s / ( select n from _X_TIME.seconds_per where period = 'second' );
    end; $$;

create view _X_TIME.seconds_comparison as (
  with v1 as (
    select generate_series( 0, 18 ) as n
    ),
    v2 as (
      select
          './.'               as title,
          n                   as n,
          ( 10 ^ n )::bigint  as s
        from v1
      union all select 'smallint',                            null,                32768
      union all select 'integer',                             null,           2147483648
      union all select 'bigint',                              null,  9223372036854775807
      union all select 'age of the universe in seconds',      null,               4.3e17
      union all select 'age of the universe in nanoseconds',  null,               4.3e26
      union all select '1 billion ppl, 1y, π billion OPS',    null, 1e9 * 31557600 * 3.1415926e9
      )
    select
        -- v2.n,
        v2.title                    as title,
        log( v2.s ) as e10,
        log( v2.s ) / log( 2 ) as e2,
        _X_TIME.age_as_text( v2.s ) as age,
        v2.s,
        -- pg_typeof( v2.s ),
        v3.*
      from
        v2,
        _X_TIME.as_fields( v2.s ) as v3
      order by e2
  );

select * from _X_TIME.seconds_comparison;

-- 3 168 808 781 402 900 000

