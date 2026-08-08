FROM node:22-alpine
WORKDIR /app
# Versions pinned to the combination verified on 2026-08-08.
# graphile-postgis publishes near-daily automated releases; bump deliberately, not implicitly.
RUN npm install postgraphile@5.1.4 graphile-postgis@3.11.7 graphile-connection-filter@2.11.7
COPY graphile.config.mjs /app/graphile.config.mjs
EXPOSE 5000
CMD ["npx", "postgraphile", "-C", "/app/graphile.config.mjs"]
