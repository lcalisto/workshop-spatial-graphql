# postgis/postgis (not plain postgres): the init dump runs
# CREATE EXTENSION postgis / postgis_raster, which needs the PostGIS packages.
FROM postgis/postgis:17-3.5-alpine
COPY ./init/ /docker-entrypoint-initdb.d/
