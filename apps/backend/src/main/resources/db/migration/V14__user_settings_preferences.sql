ALTER TABLE users
  ADD COLUMN theme_mode text NOT NULL DEFAULT 'SYSTEM',
  ADD COLUMN language text NOT NULL DEFAULT 'en';

ALTER TABLE users
  ADD CONSTRAINT users_theme_mode_check CHECK (theme_mode IN ('SYSTEM', 'LIGHT', 'DARK')),
  ADD CONSTRAINT users_language_check CHECK (language IN ('en'));
