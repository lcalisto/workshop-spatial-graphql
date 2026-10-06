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

The first start downloads a second database image (150 to 360 MB). To stop the finished workshop and delete its database, run `docker compose -f compose/final.yml down -v`. Setting the environment variable `SIMPLE_COLLECTIONS` to `both` before starting it adds cursor connections.

## After changing something in this folder

`docker compose up -d` downloads the published images named on the `image:` lines of `docker-compose.yml` and `final.yml`, and builds from this folder only when the download fails. To try a change of your own, build the images yourself. A rebuilt image does not reach a database volume that already exists, so the volume has to be deleted too. This resets the database: every SQL change you made is lost. Run:

```shell
docker compose down -v
docker compose up -d --build
```

The images you build take the names of the published ones, and later starts keep using them. To go back to the published images, run `docker compose down -v --rmi local`, then `docker compose up -d`. For the finished workshop, run the same commands with `-f compose/final.yml`.

## Updating the pinned packages

Edit [`postgraphile/package.json`](postgraphile/package.json) in this folder, then regenerate the lockfile from the root of the repository:

```shell
docker run --rm -v "$PWD/compose/postgraphile":/w -w /w node:22-alpine npm install --package-lock-only
```

Then rebuild as described above, and raise the PostGraphile tag as described below.

## Publishing the images

The workflow [`.github/workflows/images.yml`](../.github/workflows/images.yml) builds the images of this folder for amd64 and arm64 and publishes them on the GitHub Container Registry, under the tags on the `image:` lines of `docker-compose.yml` and `final.yml`. It runs after each push that changes `db/`, `postgraphile/`, a compose file or the workflow: on a branch it only checks the tags, on `main` and when started by hand it also publishes. It never replaces a tag that exists. A change here therefore needs new tags, in the same commit:

- after a change to `db/Dockerfile` or to the dump `db/init/00-initial-db.sql.gz`, raise the number at the end of `db:initial-N` in `docker-compose.yml` and of `db:final-N` in `final.yml`;
- after a change to `db/init/01-after-workshop.sql` alone, raise only `db:final-N`;
- after a change under `postgraphile/`, raise the number at the end of `postgraphile:N` in both files.

If you forget, the run fails and names the tag to raise: push a commit with the raised number. Until then, a `postgraphile` tag left behind after a change to `package.json` breaks PostGraphile on every machine that starts, because `config.js` names plugins the old image does not have. The new tags appear about ten minutes after the push; machines that start in between build the images themselves, which gives the same environment. If a run fails inside "Publish the tags", choose "Re-run failed jobs".

Old tags stay published, so older copies of the repository keep working. Raising a `db` tag without any other change publishes a database image with the current PostgreSQL and PostGIS packages, and a `db:final-N` published on its own shares fewer layers with `db:initial-N`, so the finished workshop's download grows to about 360 MB. The package pages also list untagged versions: they are the amd64 and arm64 parts of the tags, so never delete them. Never run `docker compose push` or `docker push` for these names: only the workflow publishes them. A new image name starts as a private package, and a package exists only after its first publish: put the compose change on a branch, run the workflow from it, make the new package public (Package settings, Danger Zone, Change visibility), check that it pulls without logging in, and only then merge to `main`. In a copy of this repository that changes `db/` or `postgraphile/`, delete the `image:` lines or point them at your own registry; otherwise Docker keeps pulling these images.
