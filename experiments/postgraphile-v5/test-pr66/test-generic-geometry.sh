#!/bin/sh
# Reproduces the generic geometry(Geometry,4326) verification referenced in the
# PR #66 comment (the case TBA-Lucas reported in May 2026).
# Prereq: stack running with the GA variant:
#   ./get-pr66-src.sh
#   docker compose --profile latest up -d --wait
# Then: ./test-generic-geometry.sh
set -e
URL="${GRAPHQL_URL:-http://localhost:5558/graphql}"
DB="${DB_CONTAINER:-pgv5b-db-1}"
GQL="${GQL_CONTAINER:-pgv5b-graphql_latest-1}"

echo "== adding a generic geometry column with mixed subtypes (Point + MultiPolygon) =="
docker exec "$DB" psql -U postgres -d workshop_graphql \
  -c "ALTER TABLE app_public.parcels ADD COLUMN IF NOT EXISTS geom_any geometry(Geometry,4326);" \
  -c "UPDATE app_public.parcels SET geom_any=ST_SetSRID(ST_MakePoint(-9.15,38.73),4326) WHERE id=1;" \
  -c "UPDATE app_public.parcels SET geom_any=geom WHERE id=2;" \
  -c "SELECT id, GeometryType(geom_any), ST_SRID(geom_any) FROM app_public.parcels WHERE geom_any IS NOT NULL ORDER BY id;"

echo "== restarting graphql so it re-introspects the schema =="
docker restart "$GQL" >/dev/null

echo "== waiting for the server to come back (takes ~5-15s) =="
# --retry-all-errors also covers connection resets while the server is still booting
curl -sS -o /dev/null --retry 30 --retry-delay 2 --retry-all-errors -X POST "$URL" \
  -H 'Content-Type: application/json' -d '{"query":"{ __typename }"}'
echo "server is up"

echo
echo "== schema type of Parcel.geomAny (expected: GeometryGeometry, kind INTERFACE) =="
RESP=$(curl -sS --retry 5 --retry-delay 2 --retry-all-errors -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ __type(name: \"Parcel\") { fields { name type { name kind } } } }"}')
echo "$RESP" | python3 -m json.tool 2>/dev/null | grep -B1 -A5 geomAny || echo "$RESP" | head -c 800

echo
echo "== runtime resolution (expected: row 1 GeometryPoint, row 2 GeometryMultiPolygon, srid 4326, no nulls) =="
curl -sS --retry 5 --retry-delay 2 --retry-all-errors -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ allParcels(orderBy:[ROW_ID_ASC], first:2) { nodes { rowId geomAny { __typename srid geojson } } } }"}' | head -c 700
echo
echo
echo "Optional cleanup of the test column:"
echo "  docker exec $DB psql -U postgres -d workshop_graphql -c 'ALTER TABLE app_public.parcels DROP COLUMN geom_any;'"
