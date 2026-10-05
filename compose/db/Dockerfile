# check=skip=SecretsUsedInArgOrEnv
# The password below is the workshop's public teaching password, not a secret.
#
# PostgreSQL 17 with PostGIS from the PostgreSQL apt repository, on the official postgres image,
# so it runs natively on amd64 and arm64 (the official postgis/postgis image is amd64 only).
FROM postgres:17-bookworm AS base
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-17-postgis-3 postgresql-17-postgis-3-scripts \
 && rm -rf /var/lib/apt/lists/*
# Outside the base image's VOLUME, so the restored database can be part of the image.
ENV PGDATA=/var/lib/postgresql/workshop \
    POSTGRES_DB=workshop_graphql \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=postgis

# The database as it is at the start of the workshop.
FROM base AS initial
COPY init/00-initial-db.sql.gz /docker-entrypoint-initdb.d/
RUN docker-ensure-initdb.sh

# The database as it is at the end of the workshop.
FROM base AS final
COPY init/ /docker-entrypoint-initdb.d/
RUN docker-ensure-initdb.sh
