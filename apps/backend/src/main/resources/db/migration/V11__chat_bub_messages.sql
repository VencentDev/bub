ALTER TABLE chat_messages DROP CONSTRAINT chk_chat_messages_type;
ALTER TABLE chat_messages DROP CONSTRAINT chk_chat_messages_payload;

ALTER TABLE chat_messages
  ADD CONSTRAINT chk_chat_messages_type
  CHECK (message_type IN ('TEXT', 'EMOJI', 'GIF', 'MEDIA', 'BUB'));

ALTER TABLE chat_messages
  ADD CONSTRAINT chk_chat_messages_payload
  CHECK (
    (message_type IN ('TEXT', 'EMOJI') AND body IS NOT NULL AND length(trim(body)) > 0)
    OR
    (message_type = 'GIF' AND (
      (gif_url IS NOT NULL AND length(trim(gif_url)) > 0)
      OR (gif_provider_id IS NOT NULL AND length(trim(gif_provider_id)) > 0)
    ))
    OR
    (message_type IN ('MEDIA', 'BUB') AND body IS NULL AND gif_url IS NULL AND gif_provider_id IS NULL)
  );
