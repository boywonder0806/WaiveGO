// Shared multer config for the two endpoints that accept a photo (check-in,
// enrollment). Memory storage — images are small (a single face capture) and we
// only ever forward them straight to CompreFace, no reason to touch disk.

import multer from "multer";

export const photoUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024 }, // 8MB — generous for a single JPEG capture
});
