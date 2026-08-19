# Stage 1: build the @graphile/postgis prototype from source
FROM node:22-alpine AS build
WORKDIR /plugin
COPY plugin-src/package.json plugin-src/yarn.lock ./
RUN yarn install --frozen-lockfile --ignore-scripts
# Mitigation: the lockfile pins pre-crystal#3109 rc versions which lack the
# pgCodecs_findModifiedPgCodec hook and PgCodec.baseCodec; overlay the published
# 2026-08-11 snapshot packages (same snapshot as the runtime) for type-checking.
RUN npm install --no-save --legacy-peer-deps --ignore-scripts \
      postgraphile@5.2.0-aardvark.next-20260811203155 \
      "@dataplan/pg@1.2.0-aardvark.next-20260811203155" \
      graphile-build@5.1.2-aardvark.next-20260811203155 \
      graphile-build-pg@5.2.0-aardvark.next-20260811203155
COPY plugin-src/ ./
RUN yarn build
RUN npm pack --ignore-scripts

# Stage 2: runtime with the published snapshot postgraphile
FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=build /plugin/graphile-postgis-*.tgz /app/
RUN npm install --legacy-peer-deps postgraphile@5.2.0-aardvark.next-20260811203155 pg /app/graphile-postgis-*.tgz
COPY graphile.config.mjs /app/
EXPOSE 5000
CMD ["npx", "postgraphile", "-C", "/app/graphile.config.mjs"]
