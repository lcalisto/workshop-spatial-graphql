import { PostGraphileAmberPreset } from "postgraphile/presets/amber";
import { makePgService } from "postgraphile/adaptors/pg";
import { PostgisPreset } from "@graphile/postgis";

/** @type {GraphileConfig.Preset} */
const preset = {
  extends: [PostGraphileAmberPreset, PostgisPreset],
  pgServices: [
    makePgService({
      connectionString: process.env.DATABASE_URL,
      schemas: ["app_public"],
    }),
  ],
  grafserv: {
    host: "0.0.0.0",
    port: 5000,
    graphiql: true,
  },
  grafast: {
    explain: true,
  },
};

export default preset;
