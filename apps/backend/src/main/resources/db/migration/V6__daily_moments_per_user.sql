ALTER TABLE home_daily_moments
  DROP CONSTRAINT uq_home_daily_moments_tether_date;

ALTER TABLE home_daily_moments
  ADD CONSTRAINT uq_home_daily_moments_tether_user_date
    UNIQUE (tether_connection_id, created_by_user_id, local_date);

DROP INDEX IF EXISTS idx_home_daily_moments_tether_date;

CREATE INDEX idx_home_daily_moments_tether_user_date
  ON home_daily_moments(tether_connection_id, created_by_user_id, local_date);
