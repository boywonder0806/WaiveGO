# services/api — Backend API

Stack: **Node** (framework TBD — e.g. Fastify/Express/Next.js route handlers).

Owns:

- Auth for the web dashboard and iPad app.
- The Smartwaiver API integration — looking up waivers, checking signed status, handling
  webhooks for newly-signed waivers.
- The data layer (guests, check-ins, verification results).
- The contract between the iPad app and the facial recognition service (receives match
  results, resolves them against waiver status, returns a verified/not-verified decision).

Not yet scaffolded.
