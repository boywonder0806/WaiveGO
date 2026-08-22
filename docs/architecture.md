# Architecture

## Overview

WaiveGO verifies, at check-in, whether a guest has a signed Smartwaiver waiver on file — using
facial recognition instead of asking the guest to find/re-sign it.

```
Guest face  ─┐
             ▼
       [iPad app] ── capture ──▶ [Facial Recognition service] ── match? ──▶ [API service]
                                                                                   │
                                                                     Smartwaiver API │ (waiver
                                                                                   ▼  status)
                                                                          [Smartwaiver]
                                                                                   │
                                                                                   ▼
                                                                         verified / not verified
                                                                                   │
                                                                                   ▼
                                                                          [Web dashboard]
```

## Components

- **apps/web** — Staff/admin dashboard. Check-in activity, waiver status, exceptions,
  guest management. Next.js + TypeScript.
- **apps/ipad** — Front-of-house check-in app used on iPads. Captures a guest photo and shows
  the verification result. Native SwiftUI (`apps/ipad/WaiveGO`), currently a skeleton
  idle/scanning/result flow with mocked data — no camera or service calls wired up yet.
- **services/api** — Backend of record. Node + TypeScript + Express. Owns the `guests` /
  `check_ins` data layer (`waivego-db`), the Smartwaiver API integration (waiver lookups; a
  webhook receiver stub), and calls CompreFace directly for enroll/recognize. Real endpoints
  exist (`POST /v1/checkin`, `POST /v1/guests`, `POST /v1/webhooks/smartwaiver`) — see
  `services/api/README.md`. No auth yet, and not deployed to the Droplet yet (not in
  `infra/docker-compose.yml` — see that file's TODO).
- **services/facial-recognition** — Enrolls and matches guest faces. Called by `services/api`
  during check-in. Self-hosted [CompreFace](https://github.com/exadel-inc/CompreFace) (Apache
  2.0, runs via Docker) — chosen over a managed API like AWS Rekognition so guest biometric
  data never leaves infrastructure we control. Deployment config lives in `infra/`, not this
  folder — CompreFace ships as prebuilt images, there's no WaiveGO-authored service code here
  (yet — see `infra/docker-compose.yml`'s TODO for how `services/api` will eventually front it).
- **packages/shared** — Cross-cutting TypeScript types/constants/utils shared by `apps/web` and
  `services/api` (e.g. the shape of a "check-in result").

## Open decisions

- **Face data retention**: CompreFace stores enrolled face images/embeddings by design — how
  long guest faces stay enrolled (season? indefinitely? deleted on request?) is still an open
  question, and matters for the privacy notes below.
- **Smartwaiver integration model**: `services/api` currently re-checks Smartwaiver live on
  every check-in (falling back to cached data if that call fails) rather than syncing via
  webhooks — simplest to start with, worth revisiting if Smartwaiver's rate limits become a
  concern at real volume.
- **Auth**: none of `services/api`'s endpoints require it yet. Needs to happen before it gets
  a public port (see `infra/docker-compose.yml`'s TODO).

## Hosting

Single DigitalOcean Droplet running Docker Compose — CompreFace, WaiveGO's own Postgres, and
(once built) `services/api`, all on a private Docker network with no public ports except
`services/api` behind a reverse proxy. See `infra/README.md` for the full setup runbook and
`infra/docker-compose.yml` for the stack definition. Revisit (split services onto separate
Droplets, managed Postgres, etc.) once real traffic justifies it — see the trade-off note in
`infra/README.md`.

## Data & privacy notes (to revisit before building the facial recognition service)

- Facial recognition data is sensitive (biometric) data — several US states (e.g. Illinois'
  BIPA) and other jurisdictions have specific legal requirements around consent, storage, and
  retention. This needs a real decision, not a default, before any guest face data is captured
  or stored.
