# Stage 1: build the @graphile/postgis v5 plugin from PR #66 source
FROM node:22-alpine AS plugin-build
WORKDIR /plugin
COPY graphile-postgis-fzy-v5-dargmuesli/package.json graphile-postgis-fzy-v5-dargmuesli/yarn.lock ./
# prepare script runs tsc before sources exist; skip lifecycle scripts here
RUN yarn install --frozen-lockfile --ignore-scripts
COPY graphile-postgis-fzy-v5-dargmuesli/ ./
RUN yarn build
# npm pack runs prepack (rm dist + rebuild) - fine now that deps and sources exist
RUN npm pack && ls -la *.tgz

# Stage 2: runtime app with postgraphile + the packed plugin
FROM node:22-alpine
WORKDIR /app
COPY --from=plugin-build /plugin/graphile-postgis-0.2.0.tgz /graphile-postgis.tgz
ARG POSTGRAPHILE_SPEC=postgraphile@5.0.0-rc.7
ARG DATAPLAN_PG_SPEC=
RUN npm init -y \
  && npm install --no-audit --no-fund --legacy-peer-deps \
       "${POSTGRAPHILE_SPEC}" ${DATAPLAN_PG_SPEC} pg /graphile-postgis.tgz \
  && npm ls postgraphile @dataplan/pg graphile-postgis || true
COPY graphql/graphile.config.mjs ./
EXPOSE 5000
CMD ["npx", "postgraphile", "-C", "graphile.config.mjs"]
