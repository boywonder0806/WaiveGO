// Thin client for CompreFace's Face Recognition REST API.
// Docs: https://github.com/exadel-inc/CompreFace/tree/master/docs (Face Recognition
// service section). Reached over the internal Docker network — see
// config.compreface.baseUrl — never exposed publicly (see infra/docker-compose.yml).

import { config } from "../config";

export interface RecognizedFace {
  subjectId: string;
  similarity: number;
}

interface CompreFaceRecognizeResponse {
  result?: Array<{
    subjects?: Array<{ subject: string; similarity: number }>;
  }>;
}

function authHeaders(): Record<string, string> {
  return { "x-api-key": config.compreface.recognitionApiKey };
}

/**
 * Recognizes a face against the enrolled collection. Returns the single best match
 * (or null if no face was found in the image, or the collection is empty) — the
 * caller is responsible for deciding whether the similarity score clears
 * `config.compreface.similarityThreshold`; CompreFace itself returns its best guess
 * regardless of how weak the match is.
 */
export async function recognizeFace(imageBuffer: Buffer): Promise<RecognizedFace | null> {
  const form = new FormData();
  form.append("file", new Blob([imageBuffer]), "capture.jpg");

  const response = await fetch(`${config.compreface.baseUrl}/api/v1/recognition/recognize`, {
    method: "POST",
    headers: authHeaders(),
    body: form,
  });

  if (!response.ok) {
    throw new Error(`CompreFace recognize failed: ${response.status} ${await response.text()}`);
  }

  const data = (await response.json()) as CompreFaceRecognizeResponse;
  const bestSubject = data.result?.[0]?.subjects?.[0];
  if (!bestSubject) return null;

  return { subjectId: bestSubject.subject, similarity: bestSubject.similarity };
}

/**
 * Enrolls a face image under a subject id (create the subject implicitly if it
 * doesn't exist yet — that's how CompreFace's API works, no separate "create
 * subject" call needed).
 */
export async function enrollFace(subjectId: string, imageBuffer: Buffer): Promise<void> {
  const form = new FormData();
  form.append("file", new Blob([imageBuffer]), "enroll.jpg");

  const url = new URL(`${config.compreface.baseUrl}/api/v1/recognition/faces`);
  url.searchParams.set("subject", subjectId);

  const response = await fetch(url, {
    method: "POST",
    headers: authHeaders(),
    body: form,
  });

  if (!response.ok) {
    throw new Error(`CompreFace enroll failed: ${response.status} ${await response.text()}`);
  }
}
