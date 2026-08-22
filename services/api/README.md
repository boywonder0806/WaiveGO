# services/api — Backend API

Node + TypeScript + Express. Owns:

- The Smartwaiver API integration (waiver lookups; a webhook receiver stub for new signatures).
- The CompreFace integration (enroll a guest's face, recognize a face at check-in).
- WaiveGO's own data — `guests` (links a CompreFace face to a Smartwaiver waiver) and
  `check_ins` (every scan attempt, matched or not) — see `src/db/schema.sql`.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness + DB connectivity check |
| POST | `/v1/checkin` | iPad sends a captured photo (`file`) → recognizes the face, checks the matched guest's waiver, logs the attempt, returns `{ verified, reason?, guestName? }` |
| POST | `/v1/guests` | Enroll a guest: `smartwaiverWaiverId` + a photo (`file`) → looks up the waiver, enrolls the face in CompreFace, stores the guest record |
| POST | `/v1/webhooks/smartwaiver` | Smartwaiver's new-waiver webhook — currently just logs and acknowledges (see TODO in `src/routes/webhooks.ts`) |

## Local development

Needs a Postgres to point at (either tunnel to the Droplet's `waivego-db`, or run a local
Postgres — either works, `DATABASE_URL` just needs to point at it) and CompreFace reachable
(tunnel to the Droplet's admin UI per `infra/README.md`, or point `COMPREFACE_BASE_URL` at a
local CompreFace instance if you're running one).

```bash
cp .env.example .env   # fill in DATABASE_URL, COMPREFACE_RECOGNITION_API_KEY, SMARTWAIVER_API_KEY
npm install
npm run migrate        # creates guests / check_ins tables (idempotent, safe to re-run)
npm run dev             # starts on PORT (default 3001), reloads on file change
```

`npm run typecheck` / `npm run build` / `npm start` for a production-style run without the
dev-mode file watcher.

## Deploying

Not wired into `infra/docker-compose.yml` yet — see the `TODO: waivego-api` block at the
bottom of that file for what's needed (join the `backend` network, reverse proxy in front,
that kind of thing). The `Dockerfile` here is ready for that step whenever it happens.

## Known gaps / next steps

- `/v1/checkin` re-checks Smartwaiver live on every scan (for freshness) and falls back to the
  cached `waiver_expiration` if that call fails — reasonable at kiosk volume, but worth
  revisiting if Smartwaiver's rate limits ever become a concern (see the webhook-sync
  alternative noted in `docs/architecture.md`).
- No auth on any of these endpoints yet — fine while nothing is public-facing, but this needs
  to happen before `waivego-api` gets a public port (see `infra/docker-compose.yml`'s TODO).
- Enrollment (`POST /v1/guests`) requires a manually-taken photo; pulling the enrollment photo
  automatically from Smartwaiver's Auto Photo Capture (`GET /v4/waivers/{id}/photos`) instead
  is a natural upgrade — see `docs/architecture.md`.
