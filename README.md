# WaiveGO

WaiveGO links [Smartwaiver](https://www.smartwaiver.com/) waiver signing with an in-house
facial recognition system to verify, at a glance, whether a guest has a signed waiver on file.
It ships as an iPad check-in app plus a web dashboard for staff/admins.

## How it fits together

1. A guest signs a waiver in Smartwaiver (online, or in person via the Smartwaiver kiosk/API).
2. During check-in, the iPad app captures the guest's face and runs it against the facial
   recognition service to find a matching identity.
3. The facial recognition service cross-references the match against Smartwaiver waiver status
   (via the Smartwaiver API) and returns a verified / not-verified result.
4. Staff monitor check-ins, waiver status, and exceptions from the web dashboard.

## Repo layout

This is a monorepo. Each area has its own README with more detail and current status.

```
apps/
  web/                    Staff/admin web dashboard (Next.js + TypeScript)
  ipad/                   iPad check-in app (tech stack TBD)
services/
  api/                    Backend API - Smartwaiver integration, auth, data layer (Node)
  facial-recognition/     Facial recognition / verification service (tech stack TBD)
packages/
  shared/                 Code shared across apps/services (types, constants, utils)
docs/                     Architecture notes, integration docs
infra/                    Deployment & infrastructure config
```

## Status

Early scaffolding stage — folder structure and repo are in place; app/service code has not
been written yet. See [docs/architecture.md](docs/architecture.md) for the current plan and
open decisions.

## Getting started

Not yet runnable end-to-end. Once `apps/web` and `services/api` are scaffolded, this section
will cover local setup.
