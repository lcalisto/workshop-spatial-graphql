FROM node:22-alpine
# PostGraphile 4 and the workshop plugins, at the exact versions in package-lock.json.
# PostGraphile 5 is "latest" on npm, with a different CLI and plugin system.
WORKDIR /opt/postgraphile
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
ENV PATH=/opt/postgraphile/node_modules/.bin:$PATH
EXPOSE 5000
# Options come from .postgraphilerc.js in the working directory (see docker-compose.yml).
ENTRYPOINT ["postgraphile", "--host", "0.0.0.0"]
