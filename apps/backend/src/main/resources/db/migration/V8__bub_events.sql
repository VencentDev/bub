CREATE TABLE bub_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_bub_events_distinct_users CHECK (sender_user_id <> receiver_user_id)
);

CREATE INDEX idx_bub_events_tether_created
  ON bub_events(tether_connection_id, created_at DESC);

CREATE INDEX idx_bub_events_tether_sender_created
  ON bub_events(tether_connection_id, sender_user_id, created_at DESC);

CREATE INDEX idx_bub_events_receiver_created
  ON bub_events(receiver_user_id, created_at DESC);
