# Requirements

This is a basic requirements intall for the workshop. Software install and requirements are based on `Ubuntu 20.04.3 LTS` and `Docker version 20.10.8`.

## Table of contents

1) [PostgreSQL with PostGIS extension](#1---postgresql with postgis extension)
2) [NodeJS v14.x.x](#2---nodejs-v14.x.x)
3) Pgadmin4(#3---pgadmin4)

## 1 - PostgreSQL with Postgis extension

To implement the necessary workshop PostGIS DB for connection string `postgres://postgres:postgis@localhost/workshop_graphql"`:

```bash
docker run --name "postgis-graphql" \
-v postgis-graphql:/var/lib/postgresql \
-e POSTGRES_USER=postgres \
-e POSTGRES_PASS=postgis \
-e POSTGRES_DBNAME=workshop_graphql \
-p 5432:5432 -t kartoza/postgis:13-3.1
```

## 2 - NodeJS v14.x.x

NodeJS should be install using [nvm - Node Version Manager](https://github.com/nvm-sh/nvm), for a short install nvm install: [nvm install](https://gist.github.com/d2s/372b5943bce17b964a79)

It should not be a problem is user has nodejs v14.x.x from repository.

## 3 -Pgadmin4

Implementing a simple pgadmin4 with credentials:

```bash
user: root@localhost
password: pgadmin
```

```bash
docker run --name "pgadmin-graphql" \
    -v pgadmin4-graphql:/var/lib/pgadmin \
    -v pgadmin4-servers-graphql:/pgadmin4/servers.json \
    --network host \
    -e 'PGADMIN_DEFAULT_EMAIL=root@localhost.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=pgadmin' \
    -t dpage/pgadmin4:5.7
```

Note, that we are using the host's network to be able to connect to the DB without major problems, using localhost as servername/IP on pgadmin. Inside pgadmin use the following server connection settings.

```bash
Host: localhost
Username: postgres
Password: postgis
```

![Connection pgadmin](/raw_data/pgadmin_connection_docker.png)
