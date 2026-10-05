# Support files for the workshop environment

The workshop starts with `docker compose up -d` in the root of the repository, as the [README](../README.md) explains. This folder holds what that command needs. You do not have to change anything here to follow the workshop.

## What is here

- `db/Dockerfile`: PostgreSQL 17 with PostGIS, on the official `postgres` image. The workshop database is restored while the image is built, so the database starts in seconds, and `docker compose down -v` followed by `docker compose up -d` gives a clean copy.
- `db/init/00-initial-db.sql.gz`: the workshop database.
- [`db/init/01-after-workshop.sql`](db/init/01-after-workshop.sql): every SQL statement of the README, in order, with "end of section N" markers.
- `postgraphile/`: the PostGraphile 4 image. `package.json` and `package-lock.json` fix the exact versions. The PostGraphile options are not here but in [`postgraphile/config.js`](../postgraphile/config.js) at the root of the repository.
- `pgadmin/`: the saved server and the password file that let pgAdmin open the database without asking anything.
- `final.yml`: the finished workshop as a separate environment.

## The finished workshop

Run this from the root of the repository to start the state at the end of section 8 (no users registered) on [http://localhost:5002](http://localhost:5002), next to your own environment:

```shell
docker compose -f compose/final.yml up -d
```

The first start builds a second database image, which takes a few minutes. To stop the finished workshop and delete its database, run `docker compose -f compose/final.yml down -v`. Setting the environment variable `SIMPLE_COLLECTIONS` to `both` before starting it adds cursor connections.

## After changing something in this folder

A rebuilt image does not reach a database volume that already exists, so the volume has to be deleted too. This resets the database: every SQL change you made is lost. Run:

```shell
docker compose down -v
docker compose up -d --build
```

For the finished workshop, run the same pair with `-f compose/final.yml`.

## Updating the pinned packages

Edit [`postgraphile/package.json`](postgraphile/package.json) in this folder, then regenerate the lockfile from the root of the repository:

```shell
docker run --rm -v "$PWD/compose/postgraphile":/w -w /w node:22-alpine npm install --package-lock-only
```

Then rebuild as described above.
