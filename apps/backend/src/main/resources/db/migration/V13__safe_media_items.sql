CREATE TABLE safe_media_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE,
  uploaded_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  media_type VARCHAR(16) NOT NULL,
  url TEXT NOT NULL,
  storage_object_path TEXT NOT NULL,
  content_type VARCHAR(255) NOT NULL,
  size_bytes BIGINT NOT NULL,
  original_filename TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_safe_media_items_type CHECK (media_type IN ('IMAGE', 'VIDEO')),
  CONSTRAINT chk_safe_media_items_size CHECK (size_bytes >= 0)
);

CREATE INDEX idx_safe_media_items_connection_recent
  ON safe_media_items(tether_connection_id, deleted_at, created_at DESC);

ALTER TABLE chat_messages ADD COLUMN safe_item_count INTEGER;

ALTER TABLE chat_messages DROP CONSTRAINT chk_chat_messages_type;
ALTER TABLE chat_messages DROP CONSTRAINT chk_chat_messages_payload;

ALTER TABLE chat_messages
  ADD CONSTRAINT chk_chat_messages_type
  CHECK (message_type IN ('TEXT', 'EMOJI', 'GIF', 'MEDIA', 'BUB', 'SAFE_NOTICE'));

ALTER TABLE chat_messages
  ADD CONSTRAINT chk_chat_messages_payload
  CHECK (
    (message_type IN ('TEXT', 'EMOJI') AND body IS NOT NULL AND length(trim(body)) > 0 AND safe_item_count IS NULL)
    OR
    (message_type = 'GIF' AND safe_item_count IS NULL AND (
      (gif_url IS NOT NULL AND length(trim(gif_url)) > 0)
      OR (gif_provider_id IS NOT NULL AND length(trim(gif_provider_id)) > 0)
    ))
    OR
    (message_type IN ('MEDIA', 'BUB') AND body IS NULL AND gif_url IS NULL AND gif_provider_id IS NULL AND safe_item_count IS NULL)
    OR
    (message_type = 'SAFE_NOTICE' AND body IS NULL AND gif_url IS NULL AND gif_provider_id IS NULL AND safe_item_count > 0)
  );
