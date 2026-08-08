#!/bin/sh
# Rerun the PostGraphile v5 + @graphile/postgis (PR #66) capability tests.
# Usage:
#   ./get-pr66-src.sh                                  # fetch plugin source once
#   docker compose --profile latest up -d --build      # rc.7 on :5557, 5.1.x GA on :5558
#   ./run-tests.sh                                     # tests :5557
#   GRAPHQL_URL=http://localhost:5558/graphql ./run-tests.sh
# Cleanup: docker compose --profile latest down -v
set -e
URL="${GRAPHQL_URL:-http://localhost:5557/graphql}"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "== 1. Query type field names (v5 Amber naming) =="
# retry flags: the server takes a few seconds to introspect and listen after 'up'
curl -s --retry 15 --retry-delay 2 --retry-connrefused -X POST "$URL" -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { fields { name } } } }"}'
echo

echo "== 2. Capability 1: geometry with srid + geojson (per-column concrete types) =="
curl -s -X POST "$URL" -H "Content-Type: application/json" \
  -d '{"query":"{ allMunicipalities(first: 2, orderBy: [ROW_ID_ASC]) { totalCount nodes { rowId name geom { __typename srid geojson } } } }"}' | head -c 800
echo

echo "== 3. Capability 2: sub-geometry decomposition (multipolygon -> polygons -> exterior -> points x/y) =="
curl -s -X POST "$URL" -H "Content-Type: application/json" \
  -d '{"query":"{ allParcels(first: 1) { nodes { rowId geom { srid polygons { exterior { points { x y } } interiors { points { x y } } } } } } }"}' | head -c 800
echo

echo "== 4. Capabilities 3+5: createParcel mutation with MultiPolygon GeoJSON variable =="
curl -s -X POST "$URL" -H "Content-Type: application/json" -d @"$DIR/test-mutation.json" | head -c 600
echo

echo "== NOTE: spatial filters are OUT OF SCOPE for PR #66 (no v5 connection-filter-postgis exists)."
echo "== NOTE: v4-style bare @omit smart tags are ignored; use @behavior / @name (both verified working)."
