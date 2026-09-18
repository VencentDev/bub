ALTER TABLE users
  ADD COLUMN age INTEGER,
  ADD COLUMN discovered_app_via TEXT,
  ADD COLUMN terms_accepted_at TIMESTAMPTZ;

ALTER TABLE users
  ADD CONSTRAINT users_age_check CHECK (age IS NULL OR age BETWEEN 13 AND 120),
  ADD CONSTRAINT users_discovered_app_via_check CHECK (
    discovered_app_via IS NULL
    OR discovered_app_via IN ('tiktok', 'playstore', 'recommendation', 'others')
  );
