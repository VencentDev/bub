CREATE TABLE home_daily_moments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE,
  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  local_date DATE NOT NULL,
  photo_url TEXT NOT NULL,
  partner_reaction VARCHAR(16),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT uq_home_daily_moments_tether_date UNIQUE (tether_connection_id, local_date)
);

CREATE INDEX idx_home_daily_moments_tether_date
  ON home_daily_moments(tether_connection_id, local_date);

