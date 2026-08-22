// Guest enrollment — links a face (in CompreFace) to a signed Smartwaiver waiver
// (in our own database). This is a manual/staff-driven flow for now: staff take a
// photo and provide the guest's Smartwaiver waiver id. A natural upgrade later is
// pulling the enrollment photo automatically from Smartwaiver's Auto Photo Capture
// (GET /v4/waivers/{id}/photos) instead of capturing a separate one — see
// docs/architecture.md.

import { randomUUID } from "node:crypto";
import { Router } from "express";
import { pool } from "../db/pool";
import { enrollFace } from "../services/compreface";
import { getWaiver } from "../services/smartwaiver";
import { photoUpload } from "./upload";

export const guestsRouter = Router();

guestsRouter.post("/v1/guests", photoUpload.single("file"), async (req, res) => {
  const { smartwaiverWaiverId } = req.body as { smartwaiverWaiverId?: string };

  if (!smartwaiverWaiverId) {
    return res.status(400).json({ error: "smartwaiverWaiverId is required" });
  }
  if (!req.file) {
    return res.status(400).json({ error: "A photo (field name 'file') is required" });
  }

  try {
    const waiver = await getWaiver(smartwaiverWaiverId);

    if (waiver.expired) {
      return res.status(422).json({ error: "That waiver is already expired — sign a new one before enrolling" });
    }

    const subjectId = randomUUID();
    await enrollFace(subjectId, req.file.buffer);

    const fullName = `${waiver.firstName} ${waiver.lastName}`.trim();
    const result = await pool.query(
      `INSERT INTO guests (id, compreface_subject_id, full_name, smartwaiver_waiver_id, waiver_expiration)
       VALUES ($1, $1, $2, $3, $4)
       RETURNING id, full_name, smartwaiver_waiver_id, waiver_expiration, enrolled_at`,
      [subjectId, fullName, waiver.waiverId, waiver.expirationDate]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Guest enrollment failed", err);
    res.status(502).json({ error: "Enrollment failed — see server logs" });
  }
});
