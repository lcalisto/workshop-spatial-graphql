# Requirements

This is a basic requirements install for the workshop. Everything runs on Docker; any recent Linux, macOS or Windows machine with Docker installed should work.

## Table of contents

1) [PostgreSQL with PostGIS extension](#1---postgresql-with-postgis-extension)
2) [NodeJS](#2---nodejs)
3) [Pgadmin4](#3---pgadmin4)

## 1 - PostgreSQL with PostGIS extension

To implement the necessary workshop PostGIS DB for connection string `postgres://postgres:postgis@localhost/workshop_graphql`:

```bash
docker run --name "postgis-graphql" \
-v postgis-graphql:/var/lib/postgresql \
-e POSTGRES_USER=postgres \
-e POSTGRES_PASS=postgis \
-e POSTGRES_DBNAME=workshop_graphql \
-p 5432:5432 -t kartoza/postgis:17-3.5
```

Note: the `kartoza/postgis` image is published for both amd64 and arm64, so it also runs natively on Apple Silicon Macs.

## 2 - NodeJS

NodeJS should be installed using [nvm - Node Version Manager](https://github.com/nvm-sh/nvm). Any recent LTS version works; the workshop was tested with Node 22. It should not be a problem if you already have NodeJS installed from your system repositories.

## 3 - Pgadmin4

Implementing a simple pgadmin4 with credentials:

```bash
user: root@localhost.com
password: pgadmin
```

On Linux:

```bash
docker run --name "pgadmin-graphql" \
    -v pgadmin4-graphql:/var/lib/pgadmin \
    --network host \
    -e 'PGADMIN_DEFAULT_EMAIL=root@localhost.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=pgadmin' \
    -t dpage/pgadmin4:9
```

Note, that we are using the host's network to be able to connect to the DB without major problems, using localhost as servername/IP on pgadmin. Inside pgadmin use the following server connection settings.

```bash
Host: localhost
Username: postgres
Password: postgis
```

On macOS and Windows, host networking is not available; publish a port instead:

```bash
docker run --name "pgadmin-graphql" \
    -v pgadmin4-graphql:/var/lib/pgadmin \
    -p 8080:80 \
    -e 'PGADMIN_DEFAULT_EMAIL=root@localhost.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=pgadmin' \
    -t dpage/pgadmin4:9
```

Then open `http://localhost:8080` and use `host.docker.internal` as the Host in the server connection settings (instead of localhost).

![Connection pgadmin](/raw_data/pgadmin_connection_docker.png)
