// The core check-in flow: iPad sends a captured photo -> match against enrolled
// guests in CompreFace -> confirm that guest's waiver is still valid -> verified /
// not-verified. Every attempt is logged to check_ins, matched or not, for the
// dashboard's activity feed later.

import { Router } from "express";
import { config } from "../config";
import { pool } from "../db/pool";
import { recognizeFace } from "../services/compreface";
import { getWaiver } from "../services/smartwaiver";
import { photoUpload } from "./upload";

export const checkinRouter = Router();

interface GuestRow {
  id: string;
  full_name: string;
  smartwaiver_waiver_id: string;
  waiver_expiration: string | null;
}

async function logCheckIn(
  guestId: string | null,
  result: "verified" | "not_verified_no_match" | "not_verified_expired" | "not_verified_no_waiver",
  confidence: number | null
) {
  await pool.query(
    `INSERT INTO check_ins (guest_id, result, confidence) VALUES ($1, $2, $3)`,
    [guestId, result, confidence]
  );
}

checkinRouter.post("/v1/checkin", photoUpload.single("file"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "A photo (field name 'file') is required" });
  }

  try {
    const match = await recognizeFace(req.file.buffer);

    if (!match || match.similarity < config.compreface.similarityThreshold) {
      await logCheckIn(null, "not_verified_no_match", match?.similarity ?? null);
      return res.json({ verified: false, reason: "no_match" });
    }

    const { rows } = await pool.query<GuestRow>(
      `SELECT id, full_name, smartwaiver_waiver_id, waiver_expiration FROM guests WHERE compreface_subject_id = $1`,
      [match.subjectId]
    );
    const guest = rows[0];

    if (!guest) {
      // A face CompreFace knows about but our own database doesn't — a data
      // integrity gap (e.g. enrollment partially failed), not a guest problem.
      // Log it loudly server-side but give the guest the same "not found" result.
      console.error(`CompreFace matched subject ${match.subjectId} with no corresponding guests row`);
      await logCheckIn(null, "not_verified_no_match", match.similarity);
      return res.json({ verified: false, reason: "no_match" });
    }

    // Re-check Smartwaiver live rather than trusting only the cached expiration —
    // catches a waiver that expired (or was invalidated) since enrollment. Skipped
    // entirely for test guests (TEST- prefixed, from routes/guests.ts's test-mode
    // enrollment) or when Smartwaiver isn't configured at all — there's nothing real
    // to re-check, so just use the cached value. Also falls back to the cached
    // value if a real Smartwaiver call fails, rather than failing the whole
    // check-in over a transient network issue.
    const isTestGuest = guest.smartwaiver_waiver_id.startsWith("TEST-");
    let isExpired: boolean;
    let expirationDate: string | null;

    if (isTestGuest || !config.smartwaiver.enabled) {
      expirationDate = guest.waiver_expiration;
      isExpired = expirationDate !== null && new Date(expirationDate) < new Date();
    } else {
      try {
        const waiver = await getWaiver(guest.smartwaiver_waiver_id);
        isExpired = waiver.expired;
        expirationDate = waiver.expirationDate;
        await pool.query(
          `UPDATE guests SET waiver_expiration = $1, updated_at = now() WHERE id = $2`,
          [expirationDate, guest.id]
        );
      } catch (err) {
        console.warn(`Smartwaiver re-check failed for guest ${guest.id}, falling back to cached data`, err);
        expirationDate = guest.waiver_expiration;
        isExpired = expirationDate !== null && new Date(expirationDate) < new Date();
      }
    }

    if (isExpired) {
      await logCheckIn(guest.id, "not_verified_expired", match.similarity);
      return res.json({ verified: false, reason: "expired", guestName: guest.full_name });
    }

    await logCheckIn(guest.id, "verified", match.similarity);
    return res.json({ verified: true, guestName: guest.full_name });
  } catch (err) {
    console.error("Check-in failed", err);
    res.status(502).json({ error: "Check-in failed — see server logs" });
  }
});
