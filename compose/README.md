# Finished workshop stack

This folder runs the end result of the workshop in containers: PostGraphile configured exactly as in section 8 of the [README](../README.md) (all plugins, JWT authentication, `app_anonymous` default role), plus an optional database container that restores the workshop dump and replays every SQL statement of the README ([db/init/01-after-workshop.sql](db/init/01-after-workshop.sql)).

Use it to preview the end state, to recover a broken environment, or as a starting point for your own projects.

## Usage

1. Copy the environment template and set your values:

   ```shell
   cp .env.example .env
   ```

2. Pick where the database lives:
   - **Database on your host (default).** The `graphql` service connects to it through `host.docker.internal`. Your database must already have section 8 applied (the `app_postgraphile` role must exist); put its password in `DATABASE_URL`.
   - **Everything in containers.** Uncomment the `db` service, the `depends_on` lines and the `volumes` block in [docker-compose.yml](docker-compose.yml), then point `DATABASE_URL` at it: `postgres://app_postgraphile:postgis@db/workshop_graphql` (this role and password are created by the init SQL).

3. Start the stack:

   ```shell
   docker compose up -d --build
   ```

4. Open GraphiQL at http://localhost:5433. The API uses port 5433 on purpose, so it never clashes with a workshop server running locally on port 5000. The `db` service, when enabled, publishes PostgreSQL on port 5432; its first boot takes a minute or two while the dump is restored.

If port 5432 is already taken on your host (a local PostgreSQL, for instance), change only the host side of the mapping in the compose file (for example `55432:5432`). The `graphql` service reaches the database over the internal Docker network, so that mapping only matters for tools like pgAdmin.

To reset everything: `docker compose down -v` and start again.

Note for Apple Silicon: the db image is amd64 only and runs through emulation (that is what the `platform: linux/amd64` line in the compose file is for).
