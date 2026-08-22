-- WaiveGO application schema. Run against waivego-db, NOT CompreFace's own database
-- (that one is entirely CompreFace's to manage — this schema never touches it).
--
-- gen_random_uuid() is built into Postgres core as of v13, no extension needed
-- (this project runs postgres:16-alpine — see infra/docker-compose.yml).

CREATE TABLE IF NOT EXISTS guests (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- The "subject" id this guest's face is enrolled under in CompreFace's Face
    -- Collection service. One guest <-> one CompreFace subject.
    compreface_subject_id  TEXT NOT NULL UNIQUE,
    full_name              TEXT NOT NULL,
    -- Most recent Smartwaiver waiver on file for this guest. A guest who re-signs
    -- (e.g. next season) gets this updated in place rather than a new row — the
    -- face enrollment doesn't need to change just because the waiver did.
    smartwaiver_waiver_id  TEXT NOT NULL,
    waiver_expiration      TIMESTAMPTZ,
    enrolled_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guests_smartwaiver_waiver_id ON guests (smartwaiver_waiver_id);

CREATE TABLE IF NOT EXISTS check_ins (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Null when nobody was matched (no_match result) — a check-in attempt still
    -- gets logged even if it couldn't be tied to a guest.
    guest_id    UUID REFERENCES guests (id),
    result      TEXT NOT NULL CHECK (
        result IN ('verified', 'not_verified_no_match', 'not_verified_expired', 'not_verified_no_waiver')
    ),
    -- CompreFace's similarity score for the match, if there was one (0-1).
    confidence  REAL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_check_ins_guest_id ON check_ins (guest_id);
CREATE INDEX IF NOT EXISTS idx_check_ins_created_at ON check_ins (created_at);
