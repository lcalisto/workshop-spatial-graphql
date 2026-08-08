import { PostGraphileAmberPreset } from "postgraphile/presets/amber";
import { makePgService } from "postgraphile/adaptors/pg";
import { GraphilePostgisPreset } from "graphile-postgis";
import { ConnectionFilterPreset } from "graphile-connection-filter";

/** @type {GraphileConfig.Preset} */
const preset = {
  extends: [
    PostGraphileAmberPreset,
    ConnectionFilterPreset(),
    GraphilePostgisPreset,
  ],
  pgServices: [
    makePgService({
      connectionString: process.env.DATABASE_URL,
      schemas: ["app_public"],
    }),
  ],
  grafserv: {
    port: 5000,
    host: "0.0.0.0",
    graphiql: true,
  },
};

export default preset;
