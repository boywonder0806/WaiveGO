// Receives Smartwaiver's webhook (configured via PUT /v4/webhooks-configure —
// see infra/README.md once that's set up). Smartwaiver expects a fast response
// (~10s), so this just logs and acknowledges for now.
//
// TODO: on "new-event", fetch the waiver (GET /v4/waivers/{unique_id}) and its
// photos (GET /v4/waivers/{unique_id}/photos) — if Auto Photo Capture was on, this
// can auto-enroll the guest instead of requiring the manual POST /v1/guests flow.
// Still an open question in docs/architecture.md: poll-on-demand vs. webhook-sync
// as the integration model — this stub doesn't commit to either yet.

import { Router } from "express";

export const webhooksRouter = Router();

webhooksRouter.post("/v1/webhooks/smartwaiver", (req, res) => {
  const { event, unique_id } = req.body as { event?: string; unique_id?: string };
  console.log(`Smartwaiver webhook received: event=${event} unique_id=${unique_id}`);
  res.sendStatus(200);
});
