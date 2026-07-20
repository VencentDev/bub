ALTER TABLE chat_messages DROP CONSTRAINT chk_chat_messages_type;
ALTER TABLE chat_messages DROP CONSTRAINT chk_chat_messages_payload;

ALTER TABLE chat_messages
  ADD CONSTRAINT chk_chat_messages_type CHECK (message_type IN ('TEXT', 'EMOJI', 'GIF', 'MEDIA')),
  ADD CONSTRAINT chk_chat_messages_payload CHECK (
    (message_type IN ('TEXT', 'EMOJI') AND body IS NOT NULL AND length(trim(body)) > 0)
    OR
    (message_type = 'GIF' AND (
      (gif_url IS NOT NULL AND length(trim(gif_url)) > 0)
      OR (gif_provider_id IS NOT NULL AND length(trim(gif_provider_id)) > 0)
    ))
    OR
    (message_type = 'MEDIA')
  );

CREATE TABLE chat_message_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  attachment_type VARCHAR(16) NOT NULL,
  url TEXT NOT NULL,
  storage_object_path TEXT NOT NULL,
  content_type VARCHAR(255) NOT NULL,
  size_bytes BIGINT NOT NULL,
  position INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_chat_message_attachments_type CHECK (attachment_type IN ('IMAGE', 'VIDEO')),
  CONSTRAINT chk_chat_message_attachments_size CHECK (size_bytes >= 0),
  CONSTRAINT chk_chat_message_attachments_position CHECK (position >= 0)
);

CREATE INDEX idx_chat_message_attachments_message_position
  ON chat_message_attachments(message_id, position);
