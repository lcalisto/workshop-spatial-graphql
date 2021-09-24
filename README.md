# **Workshop: Creating a Spatial GraphQL API with PostGIS and PostGraphile**

### This workshop aims to explain and exemplify the use of Postgraphile and PostgreSQL to generate a spatial GraphQL API.

----------
## Table of contents

1) [Create and restore a PostgreSQL database](#1---create-and-restore-a-postgresql-database)
2) [Using PostGraphile](#2---using-postgraphile)
3) [Pagination](#3---pagination)
4) [Filters](#4---filters)
5) [Smart tags](#5---smart-tags)
6) [Extending the schema](#6---extending-the-schema)  
	6.1) [Computed columns](#61---computed-columns)  
	6.2) [Custom queries](#62---custom-queries)
7) [CRUD Mutations](#7---crud-mutations)
8) [Authentication](#8---authentication)


----------
## What is GraphQL?

*GraphQL is a query language for your API. GraphQL isn't tied to any specific database or storage engine and is instead backed by your existing code and data.*

*A GraphQL service is created by defining types and fields on those types, then providing functions for each field on each type.*

If you are new to GraphQL it might be good to check the official documentation: https://graphql.org/learn/

----------

## Requirements

In order to move forward make sure you have installed:

- **PostgreSQL** with **PostGIS**
- **NodeJS** v14.x.x
- **npm**
- **pgAdmin4** (recommended)


----------

## 1 - Create and restore a PostgreSQL database

In order to start the workshop we will use an existing database. The ideia is to show how you can use one existing spatial database and generate a GraphQL API on top of it.

Using **pgAdmin** please create a new, empty database and then restore it using the following file [initial_db.backup](./raw_data/initial_db.backup) into the new recently created database.

### Existing database 


After restoring the DB you will see 4 tables and 3 schemas:
- **municipality**, Spatial table with portuguese municipalities.
- **population**, Non-spatial table with portuguese population per municipality;
- **parcels**, Spatial table used to collect polygons during field campaign;
- **landcover**, Spatial (vector) table with landcover for Lisbon region from [Corine 2018](https://land.copernicus.eu/pan-european/corine-land-cover/clc2018)
- **srtm**, Spatial (raster) table with SRTM for Lisbon region. 


![ERD](raw_data/db_erd.png)

#### Schemas

As mentioned [here](https://www.graphile.org/postgraphile/namespaces) 

- **app_public**, Tables and functions to be exposed to GraphQL (or any other system) - it's your public interface. This is the main part of your database.
- **app_private**, No-one should be able to read this without a SECURITY DEFINER function letting them selectively do things. This is where you store passwords (bcrypted), access tokens (hopefully encrypted), etc.
- **public**, Should be empty, used only as a default location for PostgreSQL extensions.


----------

## 2 - Using PostGraphile

In order to implement a spatial GraphQL API we will make use of PostGraphile (https://www.graphile.org). If you never used PostGraphile we recommend to check its [documentation](https://www.graphile.org/postgraphile/introduction). Part of this workshop was based on PostGraphile docs.

### PostGraphile usage forms

According to the documentation PostGraphile is formed of three forms of usage:

- **CLI**, the most user-friendly;

- **Library**, it gives more power than using the CLI, suitable for **Node.js** with **Connect**, **Express** or **Koa** applications;
  
- **Schema-only**, deepest layer which contains all the types, fields and resolvers.

**At this workshop we will use mainly the CLI**. Eventually, if we have time, we'll show a very basic library usage with NodeJS and Express.

You can check the official docs for more information on how to use the CLI, https://www.graphile.org/postgraphile/usage-cli/


Install PostGraphile globally via npm:

```shell
npm install -g postgraphile
```

### Plugins
PostGraphile can be customized using plugins. You can find more info about this on [GraphQL Schema Plugins](https://www.graphile.org/postgraphile/extending/).

We will make use of the following plugins:

- **@graphile-contrib/pg-simplify-inflector**, more info [here](https://github.com/graphile/pg-simplify-inflector)
- **@graphile/postgis** - Adds postgis support to PostGraphile, more info [here](https://github.com/graphile/postgis)
- **postgraphile-plugin-connection-filter** - Adds a powerful filtering to PostGraphile, more info [here](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter)
- **postgraphile-plugin-connection-filter-postgis** - Adds spatial filtering mechanisms into PostGraphile and the above plugin, more info [here](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter-postgis).

In order to install them we need to run: 

```shell
npm install -g \
@graphile-contrib/pg-simplify-inflector \
@graphile/postgis \
postgraphile-plugin-connection-filter \
postgraphile-plugin-connection-filter-postgis
```

More info about plugins can be found on [PostGraphile community plugins](https://www.graphile.org/postgraphile/community-plugins)

----------

### Running the server as CLI

Now that we have installed the CLI we will run it as following

```shell
postgraphile \
  --subscriptions \
  --watch \
  --dynamic-json \
  --no-setof-functions-contain-nulls \
  --no-ignore-rbac \
  --no-ignore-indexes \
  --port 5000 \
  --show-error-stack=json \
  --extended-errors hint,detail,errcode \
  --append-plugins @graphile-contrib/pg-simplify-inflector,@graphile/postgis,postgraphile-plugin-connection-filter,postgraphile-plugin-connection-filter-postgis \
  --skip-plugins graphile-build:NodePlugin \
  --simple-collections only \
  --graphiql "/" \
  --enhance-graphiql \
  --allow-explain \
  --enable-query-batching \
  --legacy-relations omit \
  --connection "postgres://postgres:postgis@localhost/workshop_graphql" \
  --schema app_public
```

This will generate a minimal schema, since we are omitting the NodePlugin, with advanced filter mechanism and postgis support given by the added plugins from above. 

### Explore the interface and current schema

Now that you run the CLI command, point your browser to [http://localhost:5000](http://localhost:5000) give it a first try. This interface is GraphiQL, a GraphQL IDE.

### First queries

Now that we setup our inital API let's query it:


- Query municipality with `ID 153`

```graphql
{
  municipality(id:153){
    name
    district
  }
}
```

- Query municipality with `ID 153` and get its population. Don't forget population table is related to the `municipalities` using attribute `DICO` .

```graphql
{
  municipality(id:153){
    name
    district
    populationByDico{
      households
      femaleResidents
      maleResidents
    }
  }
}
```

- Get all municipalities. Notice that plural connections are generated automatically `municipalitiesList`.


```graphql
{
  municipalitiesList{
    name
    district
  }
}
```

- Get all municipalities and its population.

```graphql
{
  municipalitiesList{
    name
    district
    populationByDico{
      femaleResidents
      maleResidents
      households
    }
  }
}
```

- Get `first 10` municipalities and its population.

```graphql
{
  municipalitiesList(first:10){
    name
    district
    populationByDico{
      femaleResidents
      maleResidents
      households
    }
  }
}
```

- Get all parcels.

```graphql
{
  parcelsList{
    name
    createdBy
  }
}
```
### Spatial queries

Its now time to go spatial! 

- Get the geometry as geojson and the SRID from the first municipality.

```graphql
{
  municipalitiesList(first:1) {
    name
    district
    geom{
      srid
      geojson
    }
  }
}
```
- Get the geometry as geojson and the SRID from the first parcel.

```graphql
{
  parcelsList(first:1){
    name
    createdBy
    geom{
      srid
      geojson
    }
  }
}

```

#### Geometry decomposition.

PostGraphile automatically generates sub geometries, the next query shows how that can be achived out of the box. Parcels geom column is MultiPolygon data type, therefore we can generate all sub-geometries that compose MultiPolygon.

```graphql
{
  parcelsList(first:1){
    name
    createdBy
    geom{
      srid
      geojson
      polygons{
        exterior{
          geojson
          points{
            geojson
            x
            y
          }
        }
      }
    }
  }
}

```

 ----------
## 3 - Pagination


We will not focus on this workshop on pagination but it is a very important concept in GraphQL, we recommend reading https://graphql.org/learn/pagination/ to better understand how pagination can be handled in GraphQL.

As you might have noticed on the [first queries](#First-queries) we started querying one municipality and end up with plural connections which are part of the pagination concept. 

### More queries

- Using **offset**

```graphql
{
  municipalitiesList(first:10, offset:10){
    name
    district
    populationByDico{
      femaleResidents
      maleResidents
      households
    }
  }
}
```

- Using **last**

```graphql
{
  municipalitiesList(last:10){
    name
    district
    populationByDico{
      femaleResidents
      maleResidents
      households
    }
  }
}
```

#### Relay connections

In order to have some simplicity we deactivated relay connections these type of connections come from the [Relay Cursor Connections Specification](https://relay.dev/graphql/connections.htm) for more information you should read this specification since they can be quite useful. Relay connections allows perform cursor-based pagination, and is seen as a GraphQL best practice.

We can control how PostGraphile CLI generates `collections` using:

`--simple-collections omit` "omit" - PostGraphile generates relay connections only;

`--simple-collections only` "only" - simple collections only (no Relay connections);

`--simple-collections both` "both" - both relay and simple connections.

You can try to activate both relay and simple connections, and explore the schema, please check the differences as folowing:

```shell
postgraphile \
  --subscriptions \
  --watch \
  --dynamic-json \
  --no-setof-functions-contain-nulls \
  --no-ignore-rbac \
  --no-ignore-indexes \
  --port 5000 \
  --show-error-stack=json \
  --extended-errors hint,detail,errcode \
  --append-plugins @graphile-contrib/pg-simplify-inflector,@graphile/postgis,postgraphile-plugin-connection-filter,postgraphile-plugin-connection-filter-postgis \
  --skip-plugins graphile-build:NodePlugin \
  --simple-collections both \
  --graphiql "/" \
  --enhance-graphiql \
  --allow-explain \
  --enable-query-batching \
  --legacy-relations omit \
  --connection "postgres://postgres:postgis@localhost/workshop_graphql" \
  --schema app_public
```

During this workshop we wont use relay connections anymore. You can remove them using `--simple-collections only` or just copy the CLI command from the [beginning](#Running-the-server-as-CLI).
### Note for Library usage

If you, just like me, you prefer to use simple connections but you don't like `List` suffix on the simple collections, you can remove it using `{graphileBuildOptions: {pgOmitListSuffix: true}}` to the options passed to PostGraphile library.

----------
## 4 - Filters

PostGraphile supports rudimentary filtering on connections using a **condition argument**. This condition mechanism is very limited and **does not support spatial** filtering. Therefore we will use instead [connection-filter plugin](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter) that we already installed and has advanced filter capabilities, including spatial filtering based on [postgraphile-plugin-connection-filter-postgis](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter-postgis).


By default filter is only available on fields that have indexes, this is to avoid expensive access due to missing indexes.

Lets add some indexes and see the effect in our API.
```sql
CREATE INDEX ON "app_public"."municipality"("district");

CREATE INDEX ON "app_public"."municipality"("name");

CREATE INDEX ON "app_public"."parcels"("created_by");

CREATE INDEX ON "app_public"."parcels"("name");
```


Removing option `--no-ignore-indexes` from CLI, all fields, even the ones that don't appear to be indexed, can be used on the filter. Be carefull, this action can lead to expensive access due to missing indexes.


- Query all parcels that have `benfica` :stadium: in its name.
  
```graphql
{
  parcelsList(filter: {name: {includesInsensitive: "benfica"}}) {
    name
    createdBy
  }
}

```

- Query all parcels created by `user1`:
  
```graphql
{
  parcelsList(filter: {createdBy: {like: "user1"}}) {
    name
    createdBy
  }
}
```


- Query all municipalities from Lisbon district:
  
```graphql
{
  municipalitiesList(filter: {district: {like: "Lisboa"}}) {
    name
    district
  }
}
```

- Query all municipalities **in** a list of districts
  
```graphql
{
  municipalitiesList(filter: {district: {in: ["Lisboa","Porto"]}}) {
    name
    district
    populationByDico {
      households
    }
  }
}
```

### Spatial filters

Since we have [postgraphile-plugin-connection-filter-postgis](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter-postgis) we can use spatial filters. Please take some time exploring available geometry filters in Graphiql IDE

```graphql
{
  municipalitiesList(
    filter: {
      geom: {
        bboxIntersects2D: {
          type: "Polygon"
          coordinates: [
            [
              [-9.253921508789062, 38.70855351447061]
              [-9.185256958007812, 38.70855351447061]
              [-9.185256958007812, 38.74497964505743]
              [-9.253921508789062, 38.74497964505743]
              [-9.253921508789062, 38.70855351447061]
            ]
          ]
        }
      }
    }
  ) {
    name
    district
  }
}

```

#### Using variables 

We will now get all municipalities (from municipality table) that intersect Lisbon Airport. But at the same time we will show how to use variables.

- First lets get Lisbon Airport geojson

```graphql
{
  parcelsList(first: 1, filter: { name: { like: "Lisbon airport" } }) {
    name
    createdBy
    geom {
      geojson
    }
  }
}

```

You should get the following geojson result from the previous query. Please add it to https://geojson.io and confirm its location.

```json
{
	"type": "MultiPolygon",
	"coordinates": [
		[
			[
				[
					-9.130609331,
					38.801232389
				],
				[
					-9.123779675,
					38.799759326
				],
				[
					-9.131948479,
					38.784359123
				],
				[
					-9.126725801,
					38.766548453
				],
				[
					-9.129805842,
					38.763200583
				],
				[
					-9.149223489,
					38.765611049
				],
				[
					-9.130609331,
					38.801232389
				]
			]
		]
	]
}
```

- Next lets write a query with one input variable, in this case variable name is `input1` of type GeoJSON. On this particular example we name our query `query1`.

```graphql
query query1 ($input1: GeoJSON) {
  municipalitiesList(filter: {geom: {intersects: $input1}}) {
    name
    district
  }
}
```

Now we need to insert the variable, to achive that please insert below code into QUERY VARIABLES 

```JSON
{"input1":  {
	"type": "MultiPolygon",
	"coordinates": [
		[
			[
				[
					-9.130609331,
					38.801232389
				],
				[
					-9.123779675,
					38.799759326
				],
				[
					-9.131948479,
					38.784359123
				],
				[
					-9.126725801,
					38.766548453
				],
				[
					-9.129805842,
					38.763200583
				],
				[
					-9.149223489,
					38.765611049
				],
				[
					-9.130609331,
					38.801232389
				]
			]
		]
	]
} }
```
You should have something like the image below

![Query Variables](raw_data/Screenshot1.png)

As we can see Lisbon Airport is on 2 Municipalities: Lisbon and Loures.

----------
## 5 - Smart tags

Its possible to customise PostGraphile GraphQL schema by using tags on our database tables, columns, functions etc. These can rename, omit, etc from the GraphQL schema. In other words, it allow us to change the GraphQL schema without changing the database data model.

More information on Smart tags and how to use them can be found here: https://www.graphile.org/postgraphile/smart-tags/

#### Omit
Using PgAdmin lets run the following SQL code using PgAdmin. Check what happens on the GraphQL schema.

```sql 
comment on table app_public.municipality is E'@omit';
```

As you realized all connections to municipality have been removed, although at the database level we only added one comment, nothing changed the DB.

We can remove the smart tag and revert its effect by simply remove the previous comment.

```sql 
comment on table app_public.municipality is NULL;
```

Lets now omit SRTM from our schema because its a raster dataset. We'll access it using a different technique.


```sql 
comment on table app_public.srtm is E'@omit';
```

#### Rename

In order to rename an object we can use **@name**. Please run the following to rename out table `landcover`.

```sql
comment on table app_public.landcover is E'@name clc_landcover';
```

Notice that `clc_landcover` was changed into `clcLandcover`. 

**Columns** can also be renamed.

```sql
comment on column app_public.landcover.label3 is E'@name label';
```


Moving forward on our schema simplification lets now rename a constrain (relationship) in order to have clear names. Please run the following example and check what happens in your schema, inside `population` and `municipality`.

```sql
comment on constraint population_dico_fkey on app_public.population_stat is
  E'@foreignFieldName population\n@fieldName municipality\nDocumentation here.';
```
----------
## 6 - Extending the schema

One of the most important capabilities of PostGraphile if the ability to extend GraphQL schema using functions. This gives us the ability to use the power of PostgreSQL & PostGIS to generate any processing algorithms.
### 6.1 - Computed columns

From the [docs](https://www.graphile.org/postgraphile/): *"Computed columns" add what appears to be an extra column (field) to the GraphQL table type, but, unlike an actual column, the value for this field is the result of calling a function defined in the PostgreSQL schema. This function will automatically be exposed to the resultant GraphQL schema as a field on the type; it can accept arguments that influence its result, and may return either a scalar, record, list or a set.* computed-columns/)

#### Parcels area

In this example we will generate an extra field on the parcels connection which give us the area of that parcel.

```sql
create or replace function app_public.parcels_area(p app_public.parcels)
returns real as $$
  select ST_Area(p.geom,true);
$$ language sql stable;
```

GraphQL query:
```graphql
{
  parcelsList(first: 2) {
    name
    area
  }
}
```

**Also works with filters** Make sure you removed `--no-ignore-indexes` from **PostGraphile** executable.
```graphql
{
  parcelsList(filter: {area: {greaterThan: 300000}}) {
    name
    area
    srtmList {
      min
      max
      mean
    }
  }
}
```


#### Landcover

On the next example we will generate an extra field on the parcels connection which give us one array with all intersecting landcover types.

```sql
create or replace function app_public.parcels_clc_landcover(p app_public.parcels)
returns varchar[] as $$
SELECT array_agg(distinct l.label3)
FROM app_public.landcover AS l
WHERE ST_Intersects(p.geom,l.geom)
$$ language sql stable;
```

GraphQL query:
```graphql
{
  parcelsList(first: 2) {
    name
    area
    clcLandcover
  }
}
```

**With filters**, get all parcels that intersect `Green urban areas`

```graphql
{
  parcelsList(filter: {clcLandcover: {contains: "Green urban areas"}}) {
    name
    area
    clcLandcover
  }
}
```


#### SRTM

On the next example we will generate an extra fields on the parcels connection which gives **STRM raster statistics**.


```sql
DROP TYPE IF EXISTS srtm_stats CASCADE;

CREATE TYPE srtm_stats AS (
  "min" real,
  "max" real,
  "mean" real
);

create or replace function app_public.parcels_srtm(p app_public.parcels)
returns setof srtm_stats as $$
WITH t AS (
  SELECT st_summarystats(ST_Union(ST_Clip(r.rast, ST_Transform(p.geom,3763),true))) as stats
  FROM app_public.srtm AS r
  WHERE ST_Intersects(ST_Transform(p.geom,3763),r.rast)
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;
$$ language sql stable;
```

For more information on **how to use raster data inside PostGIS** you can check my [workshop-postgis-raster](https://github.com/lcalisto/workshop-postgis-raster).

GraphQL query:
```graphql
{
  parcelsList {
    name
    area
    srtmList {
      min
      max
      mean
    }
  }
}
```

With filters:

```graphql
{
  parcelsList(filter: { name: { includesInsensitive: "benfica" } }) {
    name
    area
    srtmList {
      min
      max
      mean
    }
  }
}
```



**To discuss:** What is the difference between a computed column and a PostgreSQL generated column?
### 6.2 - Custom queries

While Computed columns generate one extra field on a specific connection, custom queries can add root-level Query fields to our GraphQL schema. This can be quite important while generating our API specially for processing algorithms.
#### Get Landcover 

On this example we are going to generate a custom query where the user can insert a GeoJSON with a geometry and a distance. It will return all landcover rows that intersect that geometry. If distance is specified the search radius will include that distance using a Buffer (ST_Buffer) around the specified geometry.

```sql
create or replace function app_public.get_landcover(geometry JSON, distance real DEFAULT NULL)
returns SETOF app_public.landcover as $$
declare
   g_geom geometry;
BEGIN
	IF distance IS NOT NULL AND distance > 0 THEN
	  IF distance > 10001  THEN
		RAISE EXCEPTION 'Maximum allowed distance for this operation is 10 km.';
	  ELSE
		g_geom=ST_SetSRID(st_buffer(ST_GeomFromGeoJSON(geometry)::geography,distance)::geometry,4326);
	  END IF;
	ELSE
	g_geom=ST_SetSRID(ST_GeomFromGeoJSON(geometry),4326);
	END IF;
	
RETURN QUERY
	SELECT *
	FROM app_public.landcover AS l
	WHERE ST_Intersects(g_geom,l.geom);
END;
$$ language plpgsql stable;
```


GraphQL query:
```graphql
{
  getLandcoverList(
    geometry: { type: "Point", coordinates: [-9.1615, 38.7122] }
    distance: 1000
  ) {
    label
  }
}
```
----------

## 7 - CRUD Mutations

----------

## 8 - Authentication
