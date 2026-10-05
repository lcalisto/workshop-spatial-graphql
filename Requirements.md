# Running the workshop without Docker

The workshop runs on Docker Compose by default, as the [README](README.md) describes. This page is for those who cannot or prefer not to use Docker, and want to follow the workshop on their own PostgreSQL and NodeJS. Everything in the README still applies; the table at the end of this page lists the commands that change.

## Table of contents

1) [PostgreSQL with PostGIS](#1---postgresql-with-postgis)
2) [Restore the workshop database](#2---restore-the-workshop-database)
3) [NodeJS, PostGraphile and the plugins](#3---nodejs-postgraphile-and-the-plugins)
4) [The configuration file](#4---the-configuration-file)
5) [Start PostGraphile](#5---start-postgraphile)
6) [What changes in the README](#6---what-changes-in-the-readme)

## 1 - PostgreSQL with PostGIS

You need PostgreSQL 12 or newer with PostGIS 3, including the `postgis_raster` extension, and a user that may create extensions (a superuser such as `postgres`). Create an empty database called `workshop_graphql`:

```shell
createdb -h localhost -U postgres workshop_graphql
```

## 2 - Restore the workshop database

Run this from the root of the repository:

```shell
pg_restore -h localhost -U postgres -d workshop_graphql --no-owner raw_data/initial_db.backup
```

Or use pgAdmin: right click the `workshop_graphql` database, choose **Restore...**, select [raw_data/initial_db.backup](raw_data/initial_db.backup) in *Filename* and press **Restore**. If pgAdmin complains about `pg_restore` (a "binary path" error), set the path under *File > Preferences > Paths > Binary paths*, matching your PostgreSQL major version.

The database now has the 5 tables and 4 schemas described in section 1 of the README.

## 3 - NodeJS, PostGraphile and the plugins

Install a NodeJS LTS version (the workshop was tested with Node 22), for example with [nvm - Node Version Manager](https://github.com/nvm-sh/nvm). Then install PostGraphile and the four plugins, at the versions the workshop was tested with:

```shell
npm install -g postgraphile@4.14.1
```

```shell
npm install -g @graphile-contrib/pg-simplify-inflector@6.1.0 @graphile/postgis@0.2.0 postgraphile-plugin-connection-filter@2.3.0 postgraphile-plugin-connection-filter-postgis@1.0.0-alpha.6
```

Keep the version numbers: PostGraphile v5 is the latest version on npm, with a different CLI and plugin system.

If the shell answers `postgraphile: command not found`, your npm global folder is not on the PATH. This is common with nvm; run `nvm use --lts` and reinstall, or add the output of `npm config get prefix`, plus `/bin`, to your PATH (on Windows, add the prefix folder itself).

## 4 - The configuration file

The file [postgraphile/config.js](postgraphile/config.js) is written for the Docker environment, where the database is reached under the name `db`. Change two lines:

- in the `connection` inside `options` (the one with the user `postgres`), replace `db` with `localhost` and set your own user and password;
- in the `connection` inside `section8`, at the top of the file, replace only `db` with `localhost`.

If your PostgreSQL does not listen on port 5432, write the port after the host name, separated by a colon.

## 5 - Start PostGraphile

```shell
cd postgraphile
postgraphile --port 5001
```

Run the command inside the `postgraphile` folder. PostGraphile looks for its configuration in the folder where it starts; without it, it starts with its defaults and gives no warning. Check the lines it prints: the one with `Postgres schema(s):` must name `app_public`. GraphiQL is then on [http://localhost:5001](http://localhost:5001), as in the README.

## 6 - What changes in the README

| The README says | Without Docker |
| --------------- | -------------- |
| `docker compose up -d` | start your PostgreSQL, then PostGraphile as in step 5 |
| `docker compose ps` | no equivalent: your PostgreSQL has to accept connections, and the terminal where PostGraphile runs has to show its start-up lines |
| `docker compose restart postgraphile` | press Ctrl+C in the terminal where PostGraphile runs, then start it again |
| `docker compose logs postgraphile` | read the terminal where PostGraphile runs |
| `docker compose exec -T db psql -U postgres -d workshop_graphql -c "..."` | `psql -h localhost -U postgres -d workshop_graphql -c "..."` |
| pgAdmin on `http://localhost:5050` | your own pgAdmin, connected to your own server |
| PostgreSQL on `localhost:15432` | your own server, usually on port 5432 |
| the reset: `docker compose down -v`, then `docker compose up -d` | stop PostGraphile, drop the `workshop_graphql` database, then repeat steps 1 and 2 of this page and continue with steps 2 and 3 of [Lost? Reset in three steps](README.md#lost-reset-in-three-steps) |
| `docker compose stop` | stop PostGraphile with Ctrl+C |
| `docker compose down -v --rmi all` | stop PostGraphile and drop the `workshop_graphql` database |
| the finished workshop (`compose/final.yml`) | not available without Docker |
