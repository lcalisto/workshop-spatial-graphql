CREATE TABLE app_public.population (
  id SERIAL PRIMARY KEY,
  dico character varying,
  m_residents INTEGER,
  f_residents INTEGER,
  households INTEGER,
  comments text,
  FOREIGN KEY (dico) REFERENCES app_public.municipalities_pt (dico)
);

CREATE INDEX ON "app_public"."population"("dico");

---------------------------------------------------------------------

ALTER TABLE app_public.municipality
    ADD CONSTRAINT municipality_dico_unique UNIQUE (dico);

ALTER TABLE app_public.population_stat
    ADD CONSTRAINT population_dico_unique UNIQUE (dico);

-----------------------------------------------------------------


CREATE TABLE app_public.parcels (
  id SERIAL PRIMARY KEY,
  geom geometry(MultiPolygon,4326),
  created_by character varying,
  comments text
);


After auth: https://www.graphile.org/postgraphile/security/

```shell
postgraphile \
  --subscriptions \
  --watch \
  --dynamic-json \
  --no-setof-functions-contain-nulls \
  --no-ignore-rbac \
  --no-ignore-indexes \
  --port 5000 \
  --show-error-stack=json \
  --extended-errors hint,detail,errcode \
  --append-plugins @graphile-contrib/pg-simplify-inflector,@graphile/postgis,postgraphile-plugin-connection-filter,postgraphile-plugin-connection-filter-postgis \
  --skip-plugins graphile-build:NodePlugin \
  --simple-collections omit \
  --graphiql "/" \
  --enhance-graphiql \
  --allow-explain \
  --jwt-secret mysecret \
  --jwt-token-identifier jwtUserToken \
  --enable-query-batching \
  --legacy-relations omit \
  --connection "postgres://postgres:postgis@localhost/workshop_graphql" \
  --schema app_public
```