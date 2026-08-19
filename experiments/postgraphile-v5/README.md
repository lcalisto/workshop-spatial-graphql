# PostGraphile v5 + PostGIS experiments

Feasibility tests for migrating this workshop from PostGraphile v4 to v5, run against the workshop's own database dump (`compose/db/init/00-initial-db.sql.gz`). Everything runs in Docker; nothing is installed on the host.

Background: PostGraphile v5 is stable since March 2026, but the official `@graphile/postgis` plugin is still v4-only. A community v5 port is in progress at [graphile/postgis#66](https://github.com/graphile/postgis/pull/66), and a third-party v5 stack exists from constructive-io ([`graphile-postgis`](https://www.npmjs.com/package/graphile-postgis)). Test results are reported as comments on the PR.

## test-constructive

Runs the workshop database on PostGraphile 5.1.4 with the constructive-io stack (`graphile-postgis` 3.11.7 + `graphile-connection-filter` 2.11.7, versions pinned); all six workshop capabilities passed, including spatial filters (via a `where:` argument).

```sh
cd test-constructive
docker compose up -d --build     # GraphiQL/Ruru at http://localhost:5556
./run-tests.sh
docker compose down -v
```

## test-pr66

Builds `@graphile/postgis` from [graphile/postgis#66](https://github.com/graphile/postgis/pull/66) (pinned to `b65f53f`) and runs it against the workshop database on postgraphile 5.0.0-rc.7 and 5.1.4 GA; results are reported on the PR.

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
