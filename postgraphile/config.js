// PostGraphile options for this workshop.
// PostGraphile reads this file when it starts: restart it after a change (the README shows how).
// Each option is the camelCase form of a CLI flag. The two "--no-..." flags used here become
// the positive name set to false (--no-ignore-rbac is ignoreRbac: false).

// The section 8 settings. They are switched on by the line "...section8" near the end of this
// file: the three dots copy these four settings into "options", where this connection replaces
// the first one.
const section8 = {
  // PostGraphile connects as app_postgraphile, a role created in section 8, instead of the
  // superuser postgres. "db" is the database container.
  connection: "postgres://app_postgraphile:postgis@db/workshop_graphql",

  // The PostgreSQL role for anonymous users, whose requests carry no JWT.
  defaultRole: "app_anonymous",

  // The secret PostGraphile uses for the JWTs. It is a public teaching value: a real deployment
  // needs a strong, unique secret.
  jwtSecret: "keyboard_kitten",

  // The composite type that PostGraphile turns into a JWT wherever it appears in the GraphQL
  // output; the authenticate function returns it.
  jwtTokenIdentifier: "app_public.jwt_token",
};

module.exports = {
  options: {
    // The PostgreSQL connection string: who connects, and to which database.
    // Here "db" is the database container.
    connection: "postgres://postgres:postgis@db/workshop_graphql",

    // Only this schema is exposed to GraphQL.
    schema: ["app_public"],

    // Watches the database and updates the GraphQL schema automatically, so SQL changes appear
    // without restarting PostGraphile.
    watch: true,

    // Generates simple list fields (like municipalitiesList) instead of cursor connections.
    // See section 3.
    simpleCollections: "only",

    // Loads the four plugins used in this workshop.
    appendPlugins: [
      "@graphile-contrib/pg-simplify-inflector",
      "@graphile/postgis",
      "postgraphile-plugin-connection-filter",
      "postgraphile-plugin-connection-filter-postgis",
    ],

    // Removes the Relay global Node interface, giving a smaller and simpler schema.
    skipPlugins: ["graphile-build:NodePlugin"],

    // Serves the GraphiQL IDE at the root URL.
    graphiql: "/",

    // Enables the full-featured GraphiQL (explorer sidebar, history and more).
    enhanceGraphiql: true,

    // Lets GraphiQL show the PostgreSQL execution plan of each query.
    allowExplain: true,

    // Enables the GraphQL subscriptions infrastructure (websockets).
    // Not used in this workshop, but harmless to keep on.
    subscriptions: true,

    // Exposes JSON values as raw JSON instead of strings.
    dynamicJson: true,

    // Declares that set-returning functions never return null rows,
    // which gives cleaner (non-nullable) types.
    setofFunctionsContainNulls: false,

    // Only exposes what the connecting role is actually allowed to access.
    // Section 8 relies on this.
    ignoreRbac: false,

    // Skips deprecated duplicate relation fields.
    legacyRelations: "omit",

    // Allows clients to send several operations in one HTTP request.
    enableQueryBatching: true,

    // These two make error responses verbose. showErrorStack adds the JavaScript stack trace;
    // extendedErrors adds the PostgreSQL hint, detail and error code.
    // Great while learning; avoid in production.
    showErrorStack: "json",
    extendedErrors: ["hint", "detail", "errcode"],

    /* Section 3: delete the two slashes at the start of the next line and restart PostGraphile. */
    // simpleCollections: "both",

    /* Section 8: delete the two slashes at the start of the next line and restart PostGraphile. */
    // ...section8,
  },
};
