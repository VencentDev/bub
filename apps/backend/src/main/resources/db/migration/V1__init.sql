CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(120),
  role VARCHAR(32) NOT NULL,
  user_type VARCHAR(32) NOT NULL,
  kyc_status VARCHAR(32) NOT NULL DEFAULT 'NONE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255)
);

CREATE INDEX idx_users_external_id ON users(external_id);
