

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


-- ---------------------------------------------------------------------------------------------------------
drop schema if exists TIME cascade;
create schema TIME;

-- ---------------------------------------------------------------------------------------------------------
create function TIME.date_from_js_timestamp( ts bigint )
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

-- ---------------------------------------------------------------------------------------------------------
create function TIME.date_from_js_timestamp( ts text )
  returns timestamp with time zone
  language sql
  immutable
  returns null on null input
  as $$
    select TIME.date_from_js_timestamp( ts::bigint );
    $$;

-- ---------------------------------------------------------------------------------------------------------
create function TIME.format( ts timestamp with time zone )
  returns text
  language sql
  immutable
  returns null on null input
  as $$
    select to_char( ts, 'YYYY Month DDth HH24:MI:SS TZ' );
    $$;

-- ---------------------------------------------------------------------------------------------------------
create function TIME.format_as_UTC( ts timestamp with time zone )
  returns text
  language sql
  immutable
  returns null on null input
  as $$
    select to_char( ts at time zone 'UTC', 'YYYY Month DDth HH24:MI:SS UTC' );
    $$;

-- ---------------------------------------------------------------------------------------------------------
create function TIME.age_as_text( age_s double precision )
  returns text immutable language sql as $$
    select ''
      || case when age_s >=        31557600                then ( age_s /  31557600 )::numeric( 16, 1 )::text || ' years'   else '' end
      || case when age_s between    2629800 and   31557600 then ( age_s /   2629800 )::numeric( 16, 1 )::text || ' months'  else '' end
      || case when age_s between     604800 and    2629800 then ( age_s /    604800 )::numeric( 16, 1 )::text || ' weeks'   else '' end
      || case when age_s between      86400 and     604800 then ( age_s /     86400 )::numeric( 16, 1 )::text || ' days'    else '' end
      || case when age_s between       3600 and      86400 then ( age_s /      3600 )::numeric( 16, 1 )::text || ' hours'   else '' end
      || case when age_s between         60 and       3600 then ( age_s /        60 )::numeric( 16, 1 )::text || ' minutes' else '' end
      || case when age_s <                              60 then ( age_s /         1 )::numeric( 16, 1 )::text || ' seconds' else '' end
      ;
  $$;
-- ---------------------------------------------------------------------------------------------------------
create function TIME.age_as_text( t timestamp with time zone )
  returns text immutable language sql as $$
    select TIME.age_as_text( extract( epoch from clock_timestamp() - t ) ) as age
  $$;








