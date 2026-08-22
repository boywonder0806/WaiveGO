import { Pool } from "pg";
import { config } from "../config";

export const pool = new Pool({ connectionString: config.database.url });

pool.on("error", (err) => {
  // A background/idle client emitted an error (e.g. connection dropped) — log it,
  // don't crash the process over a single connection hiccup.
  console.error("Unexpected error on idle Postgres client", err);
});
