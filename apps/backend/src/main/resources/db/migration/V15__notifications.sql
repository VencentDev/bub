CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tether_connection_id UUID REFERENCES tether_connections(id) ON DELETE CASCADE,
  category VARCHAR(16) NOT NULL,
  title VARCHAR(120) NOT NULL,
  body TEXT NOT NULL,
  link_path TEXT,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_notifications_category CHECK (
    category IN ('MESSAGE', 'BUB', 'SAFE', 'TETHER', 'SYSTEM')
  ),
  CONSTRAINT chk_notifications_title CHECK (length(trim(title)) > 0),
  CONSTRAINT chk_notifications_body CHECK (length(trim(body)) > 0)
);

CREATE INDEX idx_notifications_recipient_created
  ON notifications(recipient_user_id, created_at DESC, id DESC);

CREATE INDEX idx_notifications_recipient_unread
  ON notifications(recipient_user_id)
  WHERE read_at IS NULL;

CREATE INDEX idx_notifications_tether
  ON notifications(tether_connection_id);
