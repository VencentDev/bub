CREATE TABLE safe_vault_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pin_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT uq_safe_vault_access_connection_user UNIQUE (tether_connection_id, user_id)
);

CREATE INDEX idx_safe_vault_access_user_connection
  ON safe_vault_access(user_id, tether_connection_id);
