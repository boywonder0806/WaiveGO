// Loads and validates environment config once at startup — fails fast with a clear
// error rather than letting a missing var surface later as a confusing runtime crash.

import "dotenv/config";

function required(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required env var: ${name} (see .env.example)`);
  }
  return value;
}

export const config = {
  port: Number(process.env.PORT ?? 3001),

  database: {
    url: required("DATABASE_URL"),
  },

  compreface: {
    // Base URL of the CompreFace UI/API gateway container — reached over the
    // internal Docker network by container name, not a public address.
    baseUrl: process.env.COMPREFACE_BASE_URL ?? "http://compreface-ui",
    recognitionApiKey: required("COMPREFACE_RECOGNITION_API_KEY"),
    // How confident a match needs to be (0-1) to count as "found this guest" rather
    // than a false positive. CompreFace's own default threshold is 0.8.
    similarityThreshold: Number(process.env.COMPREFACE_SIMILARITY_THRESHOLD ?? 0.8),
  },

  smartwaiver: {
    baseUrl: process.env.SMARTWAIVER_BASE_URL ?? "https://api.smartwaiver.com",
    // Optional, unlike the others — this server needs to run and be testable before
    // Smartwaiver access exists (see routes/guests.ts's test-enrollment mode and
    // routes/checkin.ts's TEST- guard). Every Smartwaiver-calling code path checks
    // `enabled` first rather than assuming apiKey is set.
    apiKey: process.env.SMARTWAIVER_API_KEY,
    get enabled() {
      return Boolean(this.apiKey);
    },
  },
} as const;
