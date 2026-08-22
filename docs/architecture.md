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
- **services/api** — Backend of record. Owns the data layer, auth, and the Smartwaiver API
  integration (looking up waivers, checking signed status, webhooks for new signatures). Node.
- **services/facial-recognition** — Enrolls and matches guest faces. Called by the API/iPad app
  during check-in. Stack TBD — likely to end up as a Python service given the CV/ML library
  ecosystem (e.g. face_recognition, OpenCV, dlib), but not committed yet.
- **packages/shared** — Cross-cutting TypeScript types/constants/utils shared by `apps/web` and
  `services/api` (e.g. the shape of a "check-in result").

## Open decisions

- **Facial recognition stack**: language/framework/library, and whether face data is stored
  locally per-device, centrally, or not persisted beyond the matching step (privacy/compliance
  implications here — needs a decision before real guest data touches this system).
- **Smartwaiver integration model**: poll the Smartwaiver API on demand at check-in vs. sync
  waivers into our own datastore via webhooks and query locally.
- **Hosting/infra**: not yet decided; `infra/` is currently a placeholder.

## Data & privacy notes (to revisit before building the facial recognition service)

- Facial recognition data is sensitive (biometric) data — several US states (e.g. Illinois'
  BIPA) and other jurisdictions have specific legal requirements around consent, storage, and
  retention. This needs a real decision, not a default, before any guest face data is captured
  or stored.
