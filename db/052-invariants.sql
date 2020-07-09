

/*

888888 8888b    888 888     888     d8888 8888888b.  8888888        d8888 888b    888 88888888888 .d8888b.
  888   8888b   888 888     888    d88888 888   Y88b   888         d88888 8888b   888     888    d88P  Y88b
  888   88888b  888 888     888   d88P888 888    888   888        d88P888 88888b  888     888    Y88b.
  888   888Y88b 888 Y88b   d88P  d88P 888 888   d88P   888       d88P 888 888Y88b 888     888     "Y888b.
  888   888 Y88b888  Y88b d88P  d88P  888 8888888P"    888      d88P  888 888 Y88b888     888        "Y88b.
  888   888  Y88888   Y88o88P  d88P   888 888 T88b     888     d88P   888 888  Y88888     888          "888
  888   888   Y8888    Y888P  d8888888888 888  T88b    888    d8888888888 888   Y8888     888    Y88b  d88P
888888 8888    Y888     Y8P  d88P     888 888   T88b 8888888 d88P     888 888    Y888     888     "Y8888P"


*/



/* ###################################################################################################### */
drop schema if exists INVARIANTS cascade;
create schema INVARIANTS;

-- ---------------------------------------------------------------------------------------------------------
create table INVARIANTS.tests (
    module              text    not null,
    title               text    not null,
    values              text    not null,
    is_ok               boolean default false );

-- ---------------------------------------------------------------------------------------------------------
create view INVARIANTS.violations as select
    module,
    title,
    values
  from INVARIANTS.tests
  where not coalesce( is_ok, false );

-- ---------------------------------------------------------------------------------------------------------
create function INVARIANTS.validate()
  returns void stable parallel unsafe language plpgsql as $$
  declare
    ¶row        record;
  begin
    if ( select count(*) > 0 from ( select * from INVARIANTS.violations limit 1 ) as x ) then
      perform log( '^INVARIANTS 44644^ ------------------------------------------------------------------' );
      perform log( '^INVARIANTS 44644^ output of INVARIANTS.validate():' );
      for ¶row in ( select * from INVARIANTS.violations ) loop
        perform log( '^INVARIANTS 44644^ violation:', ¶row::text );
        end loop;
      perform log( '^INVARIANTS 44644^ ------------------------------------------------------------------' );
      raise sqlstate 'INV01' using message = '#INV01-1 Violations Detected', hint = 'see above or below';
    else
      perform log( '^INVARIANTS 44645^', 'INVARIANTS.validate(): ok' );
      end if;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function INVARIANTS.on_after_insert_into_tests_row() returns trigger language plpgsql as $$
  begin
    if not new.is_ok and ¶( 'intershop/invariants/showinserts' )::boolean then
      perform log( '^INVARIANTS 44646^ violation:', new::text );
      end if;
    return new; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function INVARIANTS.on_after_insert_into_tests_statement() returns trigger language plpgsql as $$
  begin
    if ¶( 'intershop/invariants/autovalidate' )::boolean then
      perform INVARIANTS.validate();
      end if;
    return new; end; $$;

-- ---------------------------------------------------------------------------------------------------------
create trigger on_after_insert_into_tests_row after insert on INVARIANTS.tests
  for each row execute procedure INVARIANTS.on_after_insert_into_tests_row();
create trigger on_after_insert_into_tests_statement after insert on INVARIANTS.tests
  for each statement execute procedure INVARIANTS.on_after_insert_into_tests_statement();

/* ====================================================================================================== */
\quit

