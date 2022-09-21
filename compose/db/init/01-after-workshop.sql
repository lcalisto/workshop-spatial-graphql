
comment on table app_public.municipality is E'@omit';
comment on table app_public.municipality is NULL;
comment on table app_public.srtm is E'@omit';
comment on table app_public.landcover is E'@name clc_landcover';
comment on column app_public.landcover.label3 is E'@name label';
comment on constraint population_dico_fkey on app_public.population is
  E'@foreignFieldName population\n@fieldName municipality\nDocumentation here.';

create or replace function app_public.parcels_area(p app_public.parcels)
returns real as $$
  select ST_Area(p.geom,true);
$$ language sql stable;

create or replace function app_public.parcels_clc_landcover(p app_public.parcels)
returns varchar[] as $$
SELECT array_agg(distinct l.label3)
FROM app_public.landcover AS l
WHERE ST_Intersects(p.geom,l.geom)
$$ language sql stable;



DROP TYPE IF EXISTS srtm_stats CASCADE;

CREATE TYPE srtm_stats AS (
  "min" real,
  "max" real,
  "mean" real
);

create or replace function app_public.parcels_srtm(p app_public.parcels)
returns setof srtm_stats as $$
WITH t AS (
  SELECT st_summarystats(ST_Union(ST_Clip(r.rast, ST_Transform(p.geom,3763),true))) as stats
  FROM app_public.srtm AS r
  WHERE ST_Intersects(ST_Transform(p.geom,3763),r.rast)
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;
$$ language sql stable;

create or replace function app_public.get_landcover(geometry JSON, distance real DEFAULT NULL)
returns SETOF app_public.landcover as $$
declare
   g_geom geometry;
BEGIN
	IF distance IS NOT NULL AND distance > 0 THEN
	  IF distance > 10001  THEN
		RAISE EXCEPTION 'Maximum allowed distance for this operation is 10 km.';
	  ELSE
		g_geom=ST_SetSRID(st_buffer(ST_GeomFromGeoJSON(geometry)::geography,distance)::geometry,4326);
	  END IF;
	ELSE
	g_geom=ST_SetSRID(ST_GeomFromGeoJSON(geometry),4326);
	END IF;
	
RETURN QUERY
	SELECT *
	FROM app_public.landcover AS l
	WHERE ST_Intersects(g_geom,l.geom);
END;
$$ language plpgsql stable;


--First lets remove any row without geometry
DELETE FROM app_public.parcels WHERE geom is NULL; 

ALTER TABLE app_public.parcels ALTER COLUMN geom SET NOT NULL;

comment on column app_public.parcels.id is E'@omit create,update,delete';


create table IF NOT EXISTS app_public.person (
  id               serial primary key,
  name             text unique not null check (char_length(name) < 80),
  about            text,
  created_at       timestamp default now()
);

comment on table app_public.person is 'A user of the app.';
comment on column app_public.person.id is 'The primary unique identifier for the person.';
comment on column app_public.person.name is 'The person’s name.';
comment on column app_public.person.about is 'A short description about the user, written by the user.';
comment on column app_public.person.created_at is 'The time this person was created.';


create table IF NOT EXISTS app_private.person (
  person_id        integer primary key references app_public.person(id) on delete cascade,
  email            text not null unique check (email ~* '^.+@.+\..+$'),
  password_hash    text not null
);

comment on table app_private.person is 'Private information about a person’s account.';
comment on column app_private.person.person_id is 'The id of the person associated with this account.';
comment on column app_private.person.email is 'The email address of the person.';
comment on column app_private.person.password_hash is 'An opaque hash of the person’s password.';

create extension if not exists "pgcrypto";

create or replace function app_public.register_person(
  name text,
  email text,
  password text
) returns app_public.person as $$
declare
  person app_public.person;
begin
  insert into app_public.person (name) values
    (name)
    returning * into person;

  insert into app_private.person (person_id, email, password_hash) values
    (person.id, email, crypt(password, gen_salt('bf')));

  return person;
end;
$$ language plpgsql strict security definer;

comment on function app_public.register_person(text, text, text) is 'Registers a single user and creates an account into the app.';

drop role IF EXISTS app_postgraphile;
create role app_postgraphile login password 'postgis';

drop role IF EXISTS app_anonymous;
create role app_anonymous;
grant app_anonymous to app_postgraphile;

drop role IF EXISTS app_person;
create role app_person;
grant app_person to app_postgraphile;

create type app_public.jwt_token as (
  role text,
  person_id integer,
  exp bigint
);

create function app_public.authenticate(
  email text,
  password text
) returns app_public.jwt_token as $$
declare
  account app_private.person;
begin
  select a.* into account
  from app_private.person as a
  where a.email = $1;

  if account.password_hash = crypt(password, account.password_hash) then
    return ('app_person', account.person_id, extract(epoch from (now() + interval '2 days')))::app_public.jwt_token;
  else
    return null;
  end if;
end;
$$ language plpgsql strict security definer;

comment on function app_public.authenticate(text, text) is 'Creates a JWT token that will securely identify a person and give them certain permissions. This token expires in 2 days.';

create function app_public.current_person() returns app_public.person as $$
  select *
  from app_public.person
  where id = nullif(current_setting('jwt.claims.person_id', true), '')::integer
$$ language sql stable;

comment on function app_public.current_person() is 'Gets the person who was identified by our JWT.';

alter default privileges revoke execute on functions from public;

grant usage on schema app_public to app_anonymous, app_person;

grant select on table app_public.person to app_anonymous, app_person;
grant update, delete on table app_public.person to app_person;

grant select on table app_public.landcover to app_anonymous, app_person;
grant select on table app_public.municipality to app_anonymous, app_person;
grant select on table app_public.population to app_anonymous, app_person;
grant select on table app_public.srtm to app_anonymous, app_person;
grant select on table app_public.parcels to app_anonymous, app_person;

grant insert, update, delete on table app_public.parcels to app_person;
grant usage on sequence app_public.parcels_id_seq to app_person;

grant execute on function app_public.get_landcover(json, real) to app_anonymous, app_person;
grant execute on function app_public.parcels_area(app_public.parcels) to app_anonymous, app_person;
grant execute on function app_public.parcels_clc_landcover(app_public.parcels) to app_anonymous, app_person;
grant execute on function app_public.parcels_srtm(app_public.parcels) to app_anonymous, app_person;


grant execute on function app_public.authenticate(text, text) to app_anonymous, app_person;
grant execute on function app_public.current_person() to app_anonymous, app_person;
grant execute on function app_public.register_person(text, text, text) to app_anonymous;

create policy update_person on app_public.person for update to app_person
  using (id = nullif(current_setting('jwt.claims.person_id', true), '')::integer);

create policy delete_person on app_public.person for delete to app_person
  using (id = nullif(current_setting('jwt.claims.person_id', true), '')::integer);
  
  
create policy person_parcels_insert on app_public.parcels for insert to app_person
  WITH CHECK (true);

create policy person_parcels_update on app_public.parcels for update to app_person
  USING (true);

create policy person_parcels_delete on app_public.parcels for delete to app_person
  USING (true);
  
  
 
 


