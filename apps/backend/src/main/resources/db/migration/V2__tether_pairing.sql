CREATE TABLE tether_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_one_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_two_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_tether_connections_distinct_users CHECK (user_one_id <> user_two_id)
);

CREATE INDEX idx_tether_connections_user_one_active ON tether_connections(user_one_id, active);
CREATE INDEX idx_tether_connections_user_two_active ON tether_connections(user_two_id, active);

CREATE TABLE tether_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(13) NOT NULL UNIQUE,
  creator_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  accepted_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_tether_invitations_code_format CHECK (code ~ '^BUB-[A-Z0-9]{4}-[A-Z0-9]{4}$'),
  CONSTRAINT chk_tether_invitations_not_self_accepted CHECK (
    accepted_user_id IS NULL OR accepted_user_id <> creator_user_id
  )
);

CREATE INDEX idx_tether_invitations_creator_user_id ON tether_invitations(creator_user_id);
