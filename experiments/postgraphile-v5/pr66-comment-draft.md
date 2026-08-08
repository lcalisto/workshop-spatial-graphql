# Draft comment for graphile/postgis PR #66

Copy-paste basis for a comment on <https://github.com/graphile/postgis/pull/66>. Written first person; edit freely before posting.

---

Hi @dargmuesli, I tested this branch (b65f53f) against a real-world PostGIS 3.5 database, on both `postgraphile@5.0.0-rc.7` and `postgraphile@5.1.4` (latest). Everything works on both: per-column concrete types, `srid`/`geojson` reads, sub-geometry decomposition down to point x/y, and create/update/delete mutations with GeoJSON variables (values verified in Postgres).

I also re-tested @TBA-Lucas's case: a `geometry(Geometry,4326)` column with mixed Point/MultiPolygon rows now exposes the `GeometryGeometry` interface and resolves each row to the right concrete type, no nulls. Fixed.

One note for testers: don't pin `@dataplan/pg` to the lockfile's rc.5; leave it to postgraphile's own tree (resolves to a single deduped 1.1.1).

I'd like to help land this. I can contribute: a dep bump to GA 5.1.x, mutation test fixtures (the current 60 are all read-only), and a GitHub Actions workflow to replace the dead CircleCI config. Should I open PRs against your `fzy/v5/dargmuesli` branch?
