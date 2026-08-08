FROM node:22-alpine
LABEL description="Instant high-performance GraphQL API with spatial support for your PostgreSQL database https://github.com/graphile/postgraphile"

# Install PostGraphile and plugins.
# Versions are pinned to the v4-compatible lines: PostGraphile v5 (and
# postgraphile-plugin-connection-filter v3) use a different CLI and plugin
# system and would break this workshop.
RUN npm install -g postgraphile@^4
RUN npm install -g \
        @graphile-contrib/pg-simplify-inflector@^6 \
        @graphile/postgis@^0.2.0 \
        postgraphile-plugin-connection-filter@^2 \
        postgraphile-plugin-connection-filter-postgis@1.0.0-alpha.6

EXPOSE 5000
ENTRYPOINT ["postgraphile", "-n", "0.0.0.0"]
