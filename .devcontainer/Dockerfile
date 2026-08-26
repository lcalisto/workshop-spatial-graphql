FROM node:22-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R node:node /usr/local/lib/node_modules /usr/local/bin /usr/local/share

WORKDIR /workspaces
USER node
