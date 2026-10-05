# Instructor notes

Delivery notes for running this workshop with a live group. The [README](README.md) is self-contained for attendees; this file only adds pacing and preparation advice.

## Before the session

- Ask the organisers to send attendees the [Before the workshop](README.md#before-the-workshop-try-to-do-this-at-home) checklist about a week in advance; slow venue wifi is the main risk to the schedule.
- GitHub Codespaces (see the README section) is the rescue path for attendees whose local setup fails on the day: a browser and a GitHub account are enough. A codespace runs the same Docker Compose environment, so those attendees follow the same README. Its first start builds the environment, which takes a few minutes, so anyone who plans to use it should create the codespace before the session. Codespaces needs steady venue internet and consumes the free quota of personal accounts, so treat it as the fallback, not the default.
- Rehearse the full workshop once on the machine you will present with.
- Start your own environment at home once (`docker compose up -d`), and the finished workshop too: `docker compose -f compose/final.yml up -d`. The finished workshop runs next to your own environment, with GraphiQL on http://localhost:5002. It is your safety net: a finished, working API to demo from if live coding goes wrong, and the backend for the section 8 teaser below.
- After pulling changes to this repository, rebuild both: `docker compose down -v` followed by `docker compose up -d --build`, then the same pair with `-f compose/final.yml`. A database volume that already exists keeps its old content when the image is rebuilt, which is why `down -v` deletes the volume first.
- Freeze `main` about a week before an event and tag that commit, so that the checklist the attendees follow at home and the room on the day build the same thing.
- A first start downloads images from Docker Hub, which limits how many images one network address can download without an account. A room that starts for the first time on venue wifi can reach that limit (`toomanyrequests`): one more reason to send the checklist early. On the day, `docker login` with a free account and Codespaces are the ways out.
- Keep [compose/db/init/01-after-workshop.sql](compose/db/init/01-after-workshop.sql) at hand; running it down to an "end of section N" marker rescues any attendee whose database drifted.

## Typical 3-hour delivery

Timings assume a mixed audience that knows PostgreSQL but not GraphQL.

| Time | Block |
|------|-------|
| 0:00 | Welcome, what we will build, GraphQL in 5 minutes (README intro) |
| 0:10 | Section 1: start the environment, tour of the database |
| 0:20 | Section 2: the configuration file, GraphiQL tour, first and spatial queries |
| 0:50 | Section 3: pagination |
| 1:00 | Break |
| 1:10 | Section 4: filters, spatial filters, variables |
| 1:35 | Section 5: smart tags |
| 1:50 | Section 6: computed columns and custom queries |
| 2:15 | Section 7: CRUD mutations |
| 2:30 | Section 8: authentication; fall back to the teaser below if you are behind |
| 2:55 | Wrap-up and questions |

## Cut lines, in order

When you are behind schedule, drop from this list, top first:

1. Geometry decomposition (end of section 2): show it, do not have the room type it.
2. The `simpleCollections: "both"` edit and restart in section 3: explain cursor connections on the projected screen instead of having the room edit the file.
3. Section 4: keep one attribute filter and one spatial filter, skip the rest.
4. Section 5: do `@omit` and one `@name` rename; only show the constraint rename.
5. The SRTM computed column in section 6.1: show it and point to [workshop-postgis-raster](https://github.com/lcalisto/workshop-postgis-raster) for the raster details.
6. `get_landcover` in section 6.2: run it and explain what it does, skip the line-by-line plpgsql walk.
7. Section 7: do create and update, only mention delete.
8. Section 8: switch to the teaser.

## Section 8 teaser (about 10 minutes)

A demonstration of the full auth flow against the finished workshop (`docker compose -f compose/final.yml up -d`, GraphiQL on http://localhost:5002), for when there is no time to build section 8 live:

1. As anonymous, run a `deleteParcel` mutation. It fails with a permission error; the database said no, not the API.
2. Run the `registerPerson` mutation (`m1` in the README). Note the returned id.
3. Run `authenticate` with the same email and password, and copy the JWT.
4. Open the REQUEST HEADERS tab and add `{"Authorization": "Bearer <token>"}`.
5. Re-run the delete. It works. Recap: same API, same query, different role; roles, grants and row level security all live in PostgreSQL, and PostGraphile only forwards identity.

The finished workshop is disposable: `docker compose -f compose/final.yml down -v` followed by `docker compose -f compose/final.yml up -d` puts everything back.

## Answer notes for the "To discuss" questions

**Computed column vs generated column (section 6.1).** A PostGraphile computed column is a function evaluated at query time; it exists only in the API, can join other tables, aggregate and take arguments, and its cost is paid on read. A PostgreSQL stored [generated column](https://www.postgresql.org/docs/current/ddl-generated-columns.html) (PostgreSQL 12+) is kept in the table, recalculated on write, restricted to expressions over the same row, visible to every consumer of the database and indexable (PostgreSQL 18 also adds virtual generated columns, computed on read). Rule of thumb: derived from other tables or parameterised, computed column; cheap per-row expression that every consumer should see, generated column.

**Insert both MultiPolygon and Polygon (section 7).** The `geom` column is typmod-constrained to MultiPolygon, so the generated input only accepts MultiPolygon GeoJSON. Ways around it: relax the column to generic `geometry` (loses type safety), promote on the way in with `ST_Multi()` via a trigger or a custom mutation function, or promote on the client. The custom function is the best teaching answer, since it reuses the section 6 pattern.

**Security of the pre-section-8 API (section 7).** The server connects as a superuser: anyone can read and write everything, there is no authentication, expensive spatial queries can be abused, and the verbose error options leak database internals. Section 8 fixes identity and permissions (roles, RBAC, row level security, JWT); the [production considerations](https://postgraphile.org/postgraphile/4/production/) page covers the rest (statement timeouts, hiding error details, disabling GraphiQL).
