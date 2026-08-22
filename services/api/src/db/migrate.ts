// Minimal schema setup — runs schema.sql's idempotent CREATE TABLE IF NOT EXISTS
// statements against the database. Good enough for a single-table-shape project at
// this stage; reach for a real migration tool (e.g. node-pg-migrate) once the schema
// needs to evolve without just re-running the whole file.

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { pool } from "./pool";

async function migrate() {
  const schema = readFileSync(join(__dirname, "schema.sql"), "utf-8");
  await pool.query(schema);
  console.log("Schema applied.");
  await pool.end();
}

migrate().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
