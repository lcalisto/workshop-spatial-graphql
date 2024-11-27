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

- **PostgreSQL** with **PostGIS** (you can use docker)
- **NodeJS**
- **npm**
- **pgAdmin4** (recommended)
- **QGIS** (optional, for exploring spatial features)

For install procedures for local postgreSQL and pgadmin: [here](Requirements.md)

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

In order to implement a spatial GraphQL API we will make use of PostGraphile (https://www.graphile.org). If you never used PostGraphile we recommend to check its [documentation](https://www.graphile.org/postgraphile/introduction). We also recommend these cheatsheets: https://learn.graphile.org/ 

Part of this workshop was based on PostGraphile docs.

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

Now that we have installed the CLI we will run it as following. Don't forget to replace the username, password and database_name.

```shell
postgraphile \
  --subscriptions \
  --watch \
  --dynamic-json \
  --no-setof-functions-contain-nulls \
  --no-ignore-rbac \
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
  --connection "postgres://username:password@localhost/database_name" \
  --schema app_public
```

For Windows users, run the following command instead:

```shell
postgraphile --subscriptions --watch --dynamic-json --no-setof-functions-contain-nulls --no-ignore-rbac --port 5000 --show-error-stack=json --extended-errors hint,detail,errcode --append-plugins @graphile-contrib/pg-simplify-inflector,@graphile/postgis,postgraphile-plugin-connection-filter,postgraphile-plugin-connection-filter-postgis --skip-plugins graphile-build:NodePlugin --simple-collections only --graphiql "/" --enhance-graphiql --allow-explain --enable-query-batching --legacy-relations omit --connection "postgres://username:password@localhost/database_name" --schema app_public
```

This will generate a minimal schema, since we are omitting the NodePlugin, with advanced filter mechanism and postgis support given by the added plugins from above. 

### Explore the interface and current schema

Now that you run the CLI command, point your browser to [http://localhost:5000](http://localhost:5000) give it a first try. This interface is GraphiQL, a GraphQL IDE.

PostGraphile automatically adds a number of elements to the generated GraphQL schema based on the tables and columns found in the inspected schema. For the tables from the app-public schema, it create:

- **singularized and pluralarized table types**, the singularized type, such as `landcover`, can be used to query a single record by the primary key, in this case, `id`. The pluralarized type, such as `landcoverList`, can be used to query multiple records.

- **related table types**, such as `munucipalityByDico`.
  
- **the root Query type**, 


![graphql](raw_data/graphql_interface.png)

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

Its now time to go spatial! You can always view the spatial features in **QGIS** by opening the geojson file.

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

The following query returns the 10 records after the first 10 records.

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

#### Cursor Connections

In order to have some simplicity we deactivated cursor connections these type of connections come from the [Cursor Connections Specification](https://relay.dev/graphql/connections.htm) for more information you should read this specification since they can be quite useful. Cursor connections allows perform cursor-based pagination, and is seen as a GraphQL best practice.

We can control how PostGraphile CLI generates `collections` using:

`--simple-collections omit` "omit" - PostGraphile generates cursor connections only;

`--simple-collections only` "only" - simple collections only (no cursor connections);

`--simple-collections both` "both" - both cursor and simple connections.

You can try to activate both cursor and simple connections, and explore the schema, please check the differences as following:

```shell
postgraphile \
  --subscriptions \
  --watch \
  --dynamic-json \
  --no-setof-functions-contain-nulls \
  --no-ignore-rbac \
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

During this workshop we wont use cursor connections anymore. You can remove them using `--simple-collections only` or just copy the CLI command from the [beginning](#Running-the-server-as-CLI).
### Note for Library usage

If you, just like me, you prefer to use simple connections but you don't like `List` suffix on the simple collections, you can remove it using `{graphileBuildOptions: {pgOmitListSuffix: true}}` to the options passed to PostGraphile library.

----------
## 4 - Filters

PostGraphile supports rudimentary filtering on connections using a **condition argument**. This condition mechanism is very limited and **does not support spatial** filtering. Therefore we will use instead [connection-filter plugin](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter) that we already installed and has advanced filter capabilities, including spatial filtering based on [postgraphile-plugin-connection-filter-postgis](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter-postgis).

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

More filter operations can be found [here](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter/blob/master/docs/operators.md).

### Spatial filters

Since we have [postgraphile-plugin-connection-filter-postgis](https://github.com/graphile-contrib/postgraphile-plugin-connection-filter-postgis) we can use spatial filters. Please take some time exploring available geometry filters in Graphiql IDE.

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
comment on constraint population_dico_fkey on app_public.population is
  E'@foreignFieldName population\n@fieldName municipality\nDocumentation here.';
```
----------
## 6 - Extending the schema

One of the most important capabilities of PostGraphile is the ability to extend GraphQL schema using functions. This gives us the ability to use the power of PostgreSQL & PostGIS to generate any processing algorithms.
### 6.1 - Computed columns

From the [docs](https://www.graphile.org/postgraphile/): *"Computed columns" add what appears to be an extra column (field) to the GraphQL table type, but, unlike an actual column, the value for this field is the result of calling a function defined in the PostgreSQL schema. This function will automatically be exposed to the resultant GraphQL schema as a field on the type; it can accept arguments that influence its result, and may return either a scalar, record, list or a set.

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

**Also works with filters** Make sure you don't have  `--no-ignore-indexes` option active.
```graphql
{
  parcelsList(filter: {area: {greaterThan: 300000}}) {
    name
    area
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



**To discuss:** What is the difference between a **computed column** and a PostgreSQL **generated column**?
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


From the [docs](https://www.graphile.org/postgraphile/crud-mutations/): *CRUD stands for "Create, Read, Update, Delete", is a common paradigm in data manipulation APIs; "CRUD Mutations" refer to all but the "R". PostGraphile will automatically add CRUD mutations to the schema for each table; this behaviour can be disabled via the `--disable-default-mutations` CLI setting.*

According to GraphQL convention, any operation that cause change should be sent explicitly via a mutation. Mutations in GraphQL change data, like inserting data into a database or altering data already in a database.

#### Create




In the current Parcels table we dont have any mandatory field apart from ID. In this case ID is automaticaly generated by the DB. Lets run the following code in PostgreSQL and check what happens on our GraphQL IDE.

```sql
--First lets remove any row without geometry
DELETE FROM app_public.parcels WHERE geom is NULL; 

ALTER TABLE app_public.parcels ALTER COLUMN geom SET NOT NULL;

```

```graphql
mutation {
  createParcel(
    input: { parcel: { createdBy: "userx", name: "My new parcel" } }
  ) {
    parcel {
      id
      name
      createdBy
      geom{
        geojson
      }
    }
  }
}
```

As we can see PostGraphile automatically reads the DB constrains and transposes it into our GraphQL Schema mutations.

Since ID is automaticaly generated by the DB there's no need for it to appear as a mutation input. Lets omit it with a smart tag:

```sql
comment on column app_public.parcels.id is E'@omit create,update,delete';
```
As you can see, ID no longer appears as an option in `create`, `update` or `delete` mutations.

Lets create a new parcel.

```graphql
mutation {
  createParcel(
    input: {
      parcel: {
        createdBy: "userx"
        name: "Campo grande garden"
        geom: {
          type: "MultiPolygon"
          coordinates: [
            [
              [
                [-9.155495166778564, 38.75901950184664]
                [-9.155731201171875, 38.758768515539764]
                [-9.148414134979248, 38.74879527866384]
                [-9.15259838104248, 38.75674386038564]
                [-9.155495166778564, 38.75901950184664]
              ]
            ]
          ]
        }
      }
    }
  ) {
    parcel {
      id
      name
      createdBy
      geom {
        geojson
      }
    }
  }
}
```
```graphql
query {
  parcelsList {
    id
    name
  }
}
```
Note that we must use "MultiPolygon" because our datatype is "MultiPolygon". To check the constraints of a table you can use the psql command:

```psql
\d app_public.parcels
```

**To discuss:** Is there a way to insert both "MultiPolygon" and "Polygon" GeoJSON?
#### Update

In order to update we must provide a **patch** as an input. Lets change the name of our previous parcel to `Garden in Lisbon`.

```graphql
mutation {
  updateParcel(input: { id: 5, patch: { name: "Garden in Lisbon" } }) {
    parcel {
      id
      name
      geom {
        geojson
      }
    }
  }
}
```

```graphql
query {
  parcelsList {
    id
    name
  }
}
```

#### Delete

To delete the procedure is very similar. In this case we only need to provide as an input the ID of the parcel we like to delete.

```graphql
mutation {
  deleteParcel(input: { id: 5 }) {
    parcel {
      id
      name
    }
  }
}
```

```graphql
query {
  parcelsList {
    id
    name
  }
}
```

**To discuss**: Comment the current API in terms of security and possible vulnerability.

----------

## 8 - Authentication

Authentication and authorization is incredibly important whenever you build an application. You want your users to be able to login and out of your service, and only edit the content your platform has given them permission to edit. Postgres already has great support for authentication and authorization using a secure role based system, so PostGraphile just bridges the gap between the Postgres role mechanisms and HTTP based authorization.


For more detailed info on Postgraphile authentication please check the [docs](https://www.graphile.org/postgraphile/postgresql-schema-design/#authentication-and-authorization).

We will implement a very basic Auth, later you can use this technique and functions to add more complex rules.

#### Store user info and personal data.
```sql
create table IF NOT EXISTS app_public.person (
  id               serial primary key,
  name             text unique not null check (char_length(name) < 80),
  about            text,
  created_at       timestamp default now()
);

comment on table app_public.person is 'A user of the app.';
comment on column app_public.person.id is 'The primary unique identifier for the person.';
comment on column app_public.person.name is 'The person’s name.';
comment on column app_public.person.about is 'A short description about the user, written by the user.';
comment on column app_public.person.created_at is 'The time this person was created.';

```

Passwords and other sensitive information should go into a separate schema.

```sql
create table IF NOT EXISTS app_private.person (
  person_id        integer primary key references app_public.person(id) on delete cascade,
  email            text not null unique check (email ~* '^.+@.+\..+$'),
  password_hash    text not null
);

comment on table app_private.person is 'Private information about a person’s account.';
comment on column app_private.person.person_id is 'The id of the person associated with this account.';
comment on column app_private.person.email is 'The email address of the person.';
comment on column app_private.person.password_hash is 'An opaque hash of the person’s password.';
```
#### Registering Users

Before a user can log in, they need to have an account in our database. To register a user we are going to implement a Postgres function in PL/pgSQL which will create the user on the 2 different tables. The first will be the user’s profile inserted into app_public.person, and the second will be an account inserted into app_private.person.

The pgcrypto extension should come with your Postgres distribution and gives us access to hashing functions like crypt and gen_salt which were specifically designed for hashing passwords.

```sql
create extension if not exists "pgcrypto";
```

Next lets define our registration function using a **Custom mutation**

```sql
create function app_public.register_person(
  name text,
  email text,
  password text
) returns app_public.person as $$
declare
  person app_public.person;
begin
  insert into app_public.person (name) values
    (name)
    returning * into person;

  insert into app_private.person (person_id, email, password_hash) values
    (person.id, email, crypt(password, gen_salt('bf')));

  return person;
end;
$$ language plpgsql strict security definer;

comment on function app_public.register_person(text, text, text) is 'Registers a single user and creates an account into the app.';
```

Now we have a mutation that alow us to register users but we are using a superuser in Postgraphile CLI. Lets **not register any user a moment** and check the Roles first. 

### Roles
When a user logs in, we want them to make their queries using a specific PostGraphile role. Using that role we can define rules that restrict what data the user may access.

```sql
drop role IF EXISTS app_postgraphile;
create role app_postgraphile login password 'postgis';

drop role IF EXISTS app_anonymous;
create role app_anonymous;
grant app_anonymous to app_postgraphile;

drop role IF EXISTS app_person;
create role app_person;
grant app_person to app_postgraphile;
```
#### Logging In

PostGraphile uses [JSON Web Tokens (JWTs)](https://www.graphile.org/postgraphile/postgresql-schema-design/#json-web-tokens) for authorization. We can pass an option to PostGraphile, called `--jwt-token-identifier <identifier>` in the CLI, which takes a composite type identifier. PostGraphile will turn this type into a JWT wherever you see it in the GraphQL output. So let’s define the type we will use for our JWTs:


```sql
create type app_public.jwt_token as (
  role text,
  person_id integer,
  exp bigint
);
```
Next can create a **Custom mutation** which will actually return the token JWT as follows. This function will return null if the user failed to authenticate, and a JWT token if the user succeeds. Returning null could mean that the password was incorrect, a user with their email doesn’t exist, or the client forgot to pass email and/or password arguments. If a user with the provided email does exist, and the provided password checks out with `password_hash` in `app_private.person`, then we return an instance of `app_public.jwt_token` which will then be converted into an actual JWT by PostGraphile.

```sql
create function app_public.authenticate(
  email text,
  password text
) returns app_public.jwt_token as $$
declare
  account app_private.person;
begin
  select a.* into account
  from app_private.person as a
  where a.email = $1;

  if account.password_hash = crypt(password, account.password_hash) then
    return ('app_person', account.person_id, extract(epoch from (now() + interval '2 days')))::app_public.jwt_token;
  else
    return null;
  end if;
end;
$$ language plpgsql strict security definer;

comment on function app_public.authenticate(text, text) is 'Creates a JWT token that will securely identify a person and give them certain permissions. This token expires in 2 days.';
```
#### Using the Authorized User

Now that we have the authentication function we can create another useful function that returns the logged person.

```sql
create function app_public.current_person() returns app_public.person as $$
  select *
  from app_public.person
  where id = nullif(current_setting('jwt.claims.person_id', true), '')::integer
$$ language sql stable;

comment on function app_public.current_person() is 'Gets the person who was identified by our JWT.';
```

#### Grants

Finally we need to set the grants or the Role Based Access Control (RBAC).

```sql
alter default privileges revoke execute on functions from public;

grant usage on schema app_public to app_anonymous, app_person;

grant select on table app_public.person to app_anonymous, app_person;
grant update, delete on table app_public.person to app_person;

grant select on table app_public.landcover to app_anonymous, app_person;
grant select on table app_public.municipality to app_anonymous, app_person;
grant select on table app_public.population to app_anonymous, app_person;
grant select on table app_public.srtm to app_anonymous, app_person;
grant select on table app_public.parcels to app_anonymous, app_person;

grant insert, update, delete on table app_public.parcels to app_person;
grant usage on sequence app_public.parcels_id_seq to app_person;

grant execute on function app_public.get_landcover(json, real) to app_anonymous, app_person;
grant execute on function app_public.parcels_area(app_public.parcels) to app_anonymous, app_person;
grant execute on function app_public.parcels_clc_landcover(app_public.parcels) to app_anonymous, app_person;
grant execute on function app_public.parcels_srtm(app_public.parcels) to app_anonymous, app_person;


grant execute on function app_public.authenticate(text, text) to app_anonymous, app_person;
grant execute on function app_public.current_person() to app_anonymous, app_person;
grant execute on function app_public.register_person(text, text, text) to app_anonymous;
```

Updating the CLI with:

**--connection "postgres://app_postgraphile:postgis@localhost/workshop_graphql"**  
**--default-role app_anonymous**  
**--schema app_public**  
**--jwt-secret keyboard_kitten**  
**--jwt-token-identifier app_public.jwt_token**



```shell
postgraphile \
  --subscriptions \
  --watch \
  --dynamic-json \
  --no-setof-functions-contain-nulls \
  --no-ignore-rbac \
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
  --connection "postgres://app_postgraphile:postgis@localhost/workshop_graphql" \
  --default-role app_anonymous \
  --schema app_public \
  --jwt-secret keyboard_kitten \
  --jwt-token-identifier app_public.jwt_token
```

For Windows users use the following command instead:

```shell
postgraphile --subscriptions --watch --dynamic-json --no-setof-functions-contain-nulls --no-ignore-rbac --port 5000 --show-error-stack=json --extended-errors hint,detail,errcode --append-plugins @graphile-contrib/pg-simplify-inflector,@graphile/postgis,postgraphile-plugin-connection-filter,postgraphile-plugin-connection-filter-postgis --skip-plugins graphile-build:NodePlugin --simple-collections only --graphiql "/" --enhance-graphiql --allow-explain --enable-query-batching --legacy-relations omit --connection "postgres://app_postgraphile:postgis@localhost/myapp" --default-role app_anonymous --schema app_public --jwt-secret keyboard_kitten --jwt-token-identifier app_public.jwt_token
```


Lets now register some users using our previous custom mutation:

```graphql
mutation m1 {
  registerPerson(
    input: {
      name: "user1"
      email: "user1@user1.pt"
      password: "user1@user1.pt"
    }
  ) {
    person {
      id
      name
    }
  }
}
mutation m2 {
  registerPerson(
    input: {
      name: "user2"
      email: "user2@user2.pt"
      password: "user2@user2.pt"
    }
  ) {
    person {
      id
      name
    }
  }
}
mutation m3 {
  registerPerson(
    input: {
      name: "user3"
      email: "user3@user3.pt"
      password: "user3@user3.pt"
    }
  ) {
    person {
      id
      name
    }
  }
}
```

Now that we have some users registered we can authenticate using:

```graphql
mutation {
  authenticate(input: {email: "user1@user1.pt", password: "user1@user1.pt"}) {
    jwtToken
  }
}
```
When PostGraphile gets a JWT from an HTTP request’s Authorization header should be:

```graphql
{
"Authorization": "Bearer <jwtToken>"
}
```

To confirm the auth user we can execute the following query with the correct authorization header.
```graphql
query {
  currentPerson {
    name
    id
  }
}
```

### RLS
RLS allows us to specify access to the data in our Postgres databases on a row level instead of a table level. For more info on RLS please check the official [docs](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)

```sql
alter table app_public.person enable row level security;
alter table app_public.parcels enable row level security;

create policy select_person on app_public.person for select
  using (true);

create policy select_parcels on app_public.parcels for select
  using (true);
```

Lets list all registered users.

```graphql
{
  peopleList{
    id
    name
  }
}
```

Now both anonymous users and logged in users can see all of our `app_public.person`. We also want registered users to be able to only update and delete their own row.

```sql
create policy update_person on app_public.person for update to app_person
  using (id = nullif(current_setting('jwt.claims.person_id', true), '')::integer);

create policy delete_person on app_public.person for delete to app_person
  using (id = nullif(current_setting('jwt.claims.person_id', true), '')::integer);
```

Lets update our current `user 1`

```graphql
mutation {
  updatePerson(input: { id: 7, patch: { about: "Updated user" } }) {
    person {
      id
      name
      about
    }
  }
}

```

Finally **only allow registered users** to insert, update, delete parcels.

```sql
create policy person_parcels_insert on app_public.parcels for insert to app_person
  WITH CHECK (true);

create policy person_parcels_update on app_public.parcels for update to app_person
  USING (true);

create policy person_parcels_delete on app_public.parcels for delete to app_person
  USING (true);
```

Lets now get all parcels and try to update one. Make sure you are using the proper **Authorization header**.

```graphql
query getParcels {
  parcelsList {
    id
    name
    comments
  }
}

mutation updateParcel {
  updateParcel(input: { id: 3, patch: { comments: "A stadium in Lisbon" } }) {
    parcel {
      id
      name
      comments
    }
  }
}

```
