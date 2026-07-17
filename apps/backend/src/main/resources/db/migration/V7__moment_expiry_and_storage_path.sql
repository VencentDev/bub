ALTER TABLE home_daily_moments
  ADD COLUMN storage_object_path TEXT,
  ADD COLUMN expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours');

CREATE INDEX idx_home_daily_moments_expires_at
  ON home_daily_moments(expires_at);
