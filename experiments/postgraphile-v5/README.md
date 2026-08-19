# PostGraphile v5 + PostGIS experiments

Feasibility tests for migrating this workshop from PostGraphile v4 to v5, run on 2026-08-08 against the workshop's own database dump (`compose/db/init/00-initial-db.sql.gz`). Everything runs in Docker; nothing is installed on the host.

## Background

- PostGraphile v5 went stable on 2026-03-24; npm `latest` is 5.1.4 (which also means the unpinned `npm install -g postgraphile` used elsewhere in this repo now installs v5 and breaks the v4 CLI flags).
- The official `@graphile/postgis` plugin is still v4-only. A community v5 port exists as [graphile/postgis PR #66](https://github.com/graphile/postgis/pull/66) (dargmuesli, unmerged).
- A third-party v5 stack exists: [`graphile-postgis`](https://www.npmjs.com/package/graphile-postgis) + [`graphile-connection-filter`](https://www.npmjs.com/package/graphile-connection-filter) from constructive-io.

## Results

| Capability | test-constructive | test-pr66 |
| --- | --- | --- |
| geometry field with `srid` + `geojson` | PASS | PASS (concrete per-column types) |
| sub-geometry decomposition (polygons/exterior/points x,y) | PASS (via inline fragment) | PASS |
| GeoJSON as input in query variables | PASS | PASS |
| spatial filters (`intersects`, `bboxIntersects2D`) | PASS (`where:` argument) | not in scope (no v5 filter plugin exists) |
| geometry input in CRUD mutations | PASS | PASS |
| smart tags omit/rename | PASS with v5 syntax | PASS with v5 syntax |

Common findings:

- The Amber preset keeps v4-style root field names (`allMunicipalities`, `municipalityByRowId`); the workshop's simple collections (`municipalitiesList`) and simplified names would need the v4 compat preset or `@graphile/simplify-inflection` (not tested here).
- v4-style bare `@omit` smart tags are silently ignored; `@behavior -*` and `@name` work. The workshop SQL that uses `@omit` needs converting.
- The `srtm` raster column has no v5 codec: startup warning, column dropped, no crash.
- The filter argument is `where:` (constructive fork), not v4's `filter:`; configurable via `connectionFilterArgumentName`.
- `municipality.geom` is actually `Polygon`, not `MultiPolygon` (per-column typing in test-pr66 exposed this).

## test-constructive

PostGraphile 5.1.4 + graphile-postgis 3.11.7 + graphile-connection-filter 2.11.7 (versions pinned; the package publishes near-daily automated releases). Full capability coverage including spatial filters. Trade-offs: single active maintainer, filters require constructive's connection-filter fork (incompatible with the mainstream `postgraphile-plugin-connection-filter` v3), columns typed as `GeometryInterface` with runtime subtype resolution.

```sh
cd test-constructive
docker compose up -d --build     # GraphiQL/Ruru at http://localhost:5556
./run-tests.sh
docker compose down -v
```

## test-pr66

`@graphile/postgis` built from PR #66 source (pinned to commit `b65f53f`, fetched by script), tested against both postgraphile 5.0.0-rc.7 (its lockfile target) and 5.1.4 GA; both pass. This is the future official plugin: per-column concrete geometry types, mutations fixed as of 2026-07-27. No spatial filtering (the v4 `postgraphile-plugin-connection-filter-postgis` has no v5 port; that is the main remaining ecosystem gap). Packaging note: do not pin `@dataplan/pg` to the PR lockfile's rc.5; leave it to postgraphile's own dependency tree.

```sh
cd test-pr66
./get-pr66-src.sh                              # fetch plugin source once
docker compose --profile latest up -d --build  # rc.7 on :5557, GA 5.1.x on :5558
./run-tests.sh
GRAPHQL_URL=http://localhost:5558/graphql ./run-tests.sh
./test-generic-geometry.sh                     # generic geometry(Geometry,4326) case from the PR thread
docker compose --profile latest down -v
```

## test-prototype

Tests the codec-level typmod prototype (`dargmuesli/graphile-postgis` branch `prototype/crystal-3109-codec-level-typmod`, pinned to `bd0e099`) against the published `postgraphile@5.2.0-aardvark.next-20260811203155` snapshot; results are reported on [graphile/postgis#66](https://github.com/graphile/postgis/pull/66).

```sh
cd test-prototype
./get-prototype-src.sh                # fetch plugin source once
docker compose up -d --wait           # build takes a few minutes; serves on :5560
./run-tests.sh
docker compose down -v
```
