// Guest enrollment — links a face (in CompreFace) to a guest record in our own
// database. Two modes:
//
//   - Real mode: pass `smartwaiverWaiverId` -> looks up the actual waiver on
//     Smartwaiver, uses its name/expiration. Requires SMARTWAIVER_API_KEY to be
//     configured.
//   - Test mode: pass `fullName` instead -> no Smartwaiver call at all, stores a
//     synthetic `TEST-<uuid>` waiver id with no expiration. This is what lets the
//     rest of the system (check-in, the iPad guest list) be built and tested before
//     Smartwaiver access exists — see docs/architecture.md.
//
// Same table either way. A test guest today and a real guest once Smartwaiver is
// wired up live side by side with no migration — test rows are just always
// identifiable by their TEST- prefix.
//
// A natural upgrade later, once this is real-mode-only: pull the enrollment photo
// automatically from Smartwaiver's Auto Photo Capture (GET /v4/waivers/{id}/photos)
// instead of capturing a separate one — see docs/architecture.md.

import { randomUUID } from "node:crypto";
import { Router } from "express";
import { config } from "../config";
import { pool } from "../db/pool";
import { enrollFace } from "../services/compreface";
import { getWaiver } from "../services/smartwaiver";
import { photoUpload } from "./upload";

export const guestsRouter = Router();

guestsRouter.get("/v1/guests", async (_req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, full_name, smartwaiver_waiver_id, waiver_expiration, enrolled_at
       FROM guests ORDER BY enrolled_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Failed to list guests", err);
    res.status(500).json({ error: "Failed to list guests" });
  }
});

guestsRouter.post("/v1/guests", photoUpload.single("file"), async (req, res) => {
  const { smartwaiverWaiverId, fullName: testFullName } = req.body as {
    smartwaiverWaiverId?: string;
    fullName?: string;
  };

  if (!smartwaiverWaiverId && !testFullName) {
    return res.status(400).json({ error: "Either smartwaiverWaiverId or fullName is required" });
  }
  if (!req.file) {
    return res.status(400).json({ error: "A photo (field name 'file') is required" });
  }

  try {
    let fullName: string;
    let waiverId: string;
    let waiverExpiration: string | null;

    if (smartwaiverWaiverId) {
      if (!config.smartwaiver.enabled) {
        return res.status(400).json({ error: "Smartwaiver isn't configured on this server yet — enroll with 'fullName' instead for a test guest" });
      }
      const waiver = await getWaiver(smartwaiverWaiverId);
      if (waiver.expired) {
        return res.status(422).json({ error: "That waiver is already expired — sign a new one before enrolling" });
      }
      fullName = `${waiver.firstName} ${waiver.lastName}`.trim();
      waiverId = waiver.waiverId;
      waiverExpiration = waiver.expirationDate;
    } else {
      // Test mode — no Smartwaiver call, no expiration (test guests don't expire).
      fullName = testFullName!.trim();
      waiverId = `TEST-${randomUUID()}`;
      waiverExpiration = null;
    }

    const subjectId = randomUUID();
    await enrollFace(subjectId, req.file.buffer);

    const result = await pool.query(
      `INSERT INTO guests (id, compreface_subject_id, full_name, smartwaiver_waiver_id, waiver_expiration)
       VALUES ($1, $1, $2, $3, $4)
       RETURNING id, full_name, smartwaiver_waiver_id, waiver_expiration, enrolled_at`,
      [subjectId, fullName, waiverId, waiverExpiration]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Guest enrollment failed", err);
    res.status(502).json({ error: "Enrollment failed — see server logs" });
  }
});
