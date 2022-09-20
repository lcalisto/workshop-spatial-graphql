FROM node:alpine
LABEL description="Instant high-performance GraphQL API with spatial support for your PostgreSQL database https://github.com/graphile/postgraphile"

# Install PostGraphile and PostGraphile connection filter plugin
RUN npm install -g \
        @graphile-contrib/pg-simplify-inflector \
        @graphile/postgis \
        postgraphile-plugin-connection-filter \
        postgraphile-plugin-connection-filter-postgis

EXPOSE 5000
ENTRYPOINT ["postgraphile", "-n", "0.0.0.0"]