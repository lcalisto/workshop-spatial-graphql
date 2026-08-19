#!/bin/sh
# Prototype (codec-level typmod) capability tests against the published
# postgraphile@5.2.0-aardvark.next-20260811203155 snapshot.
# Prereq:
#   ./get-prototype-src.sh
#   docker compose up -d --wait      # build takes a few minutes
set -e
URL="${GRAPHQL_URL:-http://localhost:5560/graphql}"
DB="${DB_CONTAINER:-pgv5c-db-1}"
GQL="${GQL_CONTAINER:-pgv5c-graphql-1}"
DIR="$(cd "$(dirname "$0")" && pwd)"

# gql <json> : POST a query, print the first 500 chars of the response.
# Response goes into a variable first - piping curl straight into head aborts
# the transfer (curl error 23) once head closes the pipe.
gql() {
  RESP=$(curl -sS --retry 15 --retry-delay 2 --retry-all-errors -X POST "$URL" -H 'Content-Type: application/json' -d "$1")
  printf '%s' "$RESP" | head -c 500
  echo
}

echo "== 1. regression: concrete per-column types + srid/geojson =="
gql '{"query":"{ allMunicipalities(first: 2, orderBy: [ROW_ID_ASC]) { nodes { name geom { __typename srid geojson } } } }"}'
echo
echo "== 2. regression: MultiPolygon decomposition =="
gql '{"query":"{ allParcels(first: 1, orderBy: [ROW_ID_ASC]) { nodes { geom { __typename srid polygons { exterior { points { x y } } } } } } }"}'
echo
echo "== 3. regression: createParcel with GeoJSON variable =="
gql "$(cat "$DIR/test-c-mutation.json")"
echo
echo "== 4. THE CODEC-LEVEL HEADLINE: a VIEW narrows to the concrete type =="
docker exec "$DB" psql -U postgres -d workshop_graphql \
  -c "CREATE OR REPLACE VIEW app_public.municipality_simple AS SELECT id, name, geom FROM app_public.municipality;" \
  -c "GRANT SELECT ON app_public.municipality_simple TO PUBLIC;"
docker restart "$GQL" >/dev/null
curl -sS -o /dev/null --retry 30 --retry-delay 2 --retry-all-errors -X POST "$URL" -H 'Content-Type: application/json' -d '{"query":"{ __typename }"}'
echo "   expected: geom -> OBJECT GeometryPolygon (NOT the interface)"
RESP=$(curl -sS --retry 5 --retry-delay 2 --retry-all-errors -X POST "$URL" -H 'Content-Type: application/json' \
  -d '{"query":"{ __type(name: \"MunicipalitySimple\") { fields { name type { name kind ofType { name } } } } }"}')
printf '%s' "$RESP" | python3 -m json.tool 2>/dev/null | grep -B1 -A6 '"geom"' || printf '%s' "$RESP" | head -c 500
gql '{"query":"{ allMunicipalitySimples(first: 1) { nodes { name geom { __typename srid } } } }"}'
echo
echo "== 5. known gap: function returning geometry -> interface + silent NULL at runtime =="
docker exec "$DB" psql -U postgres -d workshop_graphql \
  -c "CREATE OR REPLACE FUNCTION app_public.parcels_centroid(p app_public.parcels) RETURNS geometry(Point,4326) AS \$\$ SELECT ST_Centroid(p.geom)::geometry(Point,4326) \$\$ LANGUAGE sql STABLE;"
docker restart "$GQL" >/dev/null
curl -sS -o /dev/null --retry 30 --retry-delay 2 --retry-all-errors -X POST "$URL" -H 'Content-Type: application/json' -d '{"query":"{ __typename }"}'
gql '{"query":"{ allParcels(first: 1) { nodes { rowId centroid { __typename srid geojson } } } }"}'
echo "   EXPECTED at bd0e099 + snapshot 20260811203155: centroid is GeometryInterface in the schema (PostgreSQL"
echo "   discards return-type typmods, so the interface fallback is correct) and the VALUE IS NULL at runtime"
echo "   (bug: PostgisColumnsPlugin only re-plans table attribute fields). Reported on PR #66."
echo
echo "Cleanup: docker compose down -v"
