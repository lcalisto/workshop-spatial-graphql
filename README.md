# **Workshop: Creating a Spatial GraphQL API with PostGIS and PostGraphile**

### This workshop aims to explain and exemplify the use of Postgraphile and PostgreSQL to generate a spatial GraphQL API.

## What is GraphQL?

*GraphQL is a query language for your API. GraphQL isn't tied to any specific database or storage engine and is instead backed by your existing code and data.*

*A GraphQL service is created by defining types and fields on those types, then providing functions for each field on each type.*

If you are new to GraphQL it might be good to check the official documentation: https://graphql.org/learn/

----------

## Requirements

In order to move forward make sure you have instaled:

- **PostgreSQL** with **PostGIS**
- **npm**
- **pgAdmin4** (recomended)


----------

## 1 - Create and restore a PostgreSQL database

In order to start the workshop we will use an existing database. The ideia is to show how you can use one existing spatial database and generate a GraphQL API on top of it.

Using **pgAdmin** please create a new, empty database and then restore it using the following file [initial_db.backup](./raw_data/initial_db.backup) into the new recently created database.

### Existing database 


After restoring the DB you will see 4 tables and 3 schemas:
- **municipality**, Spatial table with portuguese municipalities.
- **population**, Non-spatial table with portuguese population per municipality;
- **landcover**, Spatial (vector) table with landcover for Lisbon region from 2018 [from here](https://www.dgterritorio.gov.pt/Carta-de-Uso-e-Ocupacao-do-Solo-para-2018).
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

----------

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
  --simple-collections omit \
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

### First queries {#First-queries}

Now that we setup our inital API lest run some queries:


1) Query municipality with `ID 153`

```graphql
{
  municipality(id:153){
    name
    district
  }
}
```

2) Query municipality with `ID 153` and get its population. Don't forget population table is related to the `municipalities` using attribute `DICO` .

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

3) Get all municipalities. Notice that plural connections are generated automatically `municipalitiesList`.


```graphql
{
  municipalitiesList{
    name
    district
  }
}
```

4) Get all municipalities and its population.

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

5) Get `first 10` municipalities and its population.

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


## 3 - Pagination

As you might have noticed on the [first queries](#First-queries) we started 

https://graphql.org/learn/pagination/

https://relay.dev/graphql/connections.htm

`--simple-collections only` "omit" (default) - relay connections only, "only" - simple collections only (no Relay connections), "both" - both


You can simplify the inflector further by adding `{graphileBuildOptions: {pgOmitListSuffix: true}}` to the options passed to PostGraphile library.


## 4 - Filter 

To use the filter we should have an index:

```sql
CREATE INDEX ON "app_public"."municipalities"("district");
```

Or simply remove option `--no-ignore-indexes` from CLI. Be carefull, this action can lead to expensive access due to missing indexes.
## 5 - Smart tags
https://www.graphile.org/postgraphile/smart-tags/

```sql 
comment on table landcover is E'@omit';
comment on table app_public.landcover is NULL;
```

Another example a bit more complex. Renaming relationship in order to have clear names.

```sql
comment on constraint population_dico_fkey on app_public.population_stat is
  E'@foreignFieldName population\n@fieldName municipality\nDocumentation here.';
```

## 6 - Extending the schema
### Computed columns

### Custom queries

## 7 - CRUD Mutations

## 8 - Authentication