#!/bin/sh
# Rerun the PostGraphile v5 + graphile-postgis capability tests.
# Usage:
#   docker compose up -d --build     # wait for db healthy (dump restore takes ~1 min)
#   ./run-tests.sh
# Cleanup: docker compose down -v
set -e
URL="${GRAPHQL_URL:-http://localhost:5556/graphql}"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "== 1. Query type field names (v5 Amber naming) =="
# retry flags: the server takes a few seconds to introspect and listen after 'up'
curl -s --retry 15 --retry-delay 2 --retry-connrefused -X POST "$URL" -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { fields { name } } } }"}'
echo

echo "== 2. Capability 1: geometry with srid + geojson =="
curl -s -X POST "$URL" -H "Content-Type: application/json" \
  -d '{"query":"{ allMunicipalities(first: 2) { totalCount nodes { rowId name geom { __typename srid geojson } } } }"}' | head -c 800
echo

echo "== 3. Capability 2: sub-geometry decomposition (multipolygon -> polygons -> exterior -> points x/y) =="
curl -s -X POST "$URL" -H "Content-Type: application/json" \
  -d '{"query":"{ allParcels { nodes { rowId geom { __typename srid ... on GeometryMultiPolygon { polygons { exterior { points { x y } } } } } } } }"}' | head -c 800
echo

echo "== 4. Capabilities 3+4: spatial filter (intersects + bboxIntersects2D) with GeoJSON variable =="
curl -s -X POST "$URL" -H "Content-Type: application/json" -d @"$DIR/test-intersects.json"
echo

echo "== 5. Capability 5: createParcel mutation with MultiPolygon GeoJSON input =="
curl -s -X POST "$URL" -H "Content-Type: application/json" -d @"$DIR/test-mutation.json" | head -c 600
echo

echo "== 6. Capability 6: smart tags (apply in db, then restart the graphql container) =="
echo "   docker exec pgv5a-db-1 psql -U postgres -d workshop_graphql \\"
echo "     -c \"COMMENT ON TABLE app_public.landcover IS E'@behavior -*';\" \\"
echo "     -c \"COMMENT ON COLUMN app_public.municipality.nutsiii IS E'@name nuts3';\""
echo "   NOTE: v4-style bare @omit is IGNORED by the Amber preset; use @behavior (or the v4 compat preset)."
