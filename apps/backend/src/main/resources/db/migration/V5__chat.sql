CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_type VARCHAR(16) NOT NULL,
  body TEXT,
  gif_url TEXT,
  gif_provider_id VARCHAR(255),
  reply_to_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  edited_at TIMESTAMPTZ,
  deleted_for_everyone_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT chk_chat_messages_type CHECK (message_type IN ('TEXT', 'EMOJI', 'GIF')),
  CONSTRAINT chk_chat_messages_payload CHECK (
    (message_type IN ('TEXT', 'EMOJI') AND body IS NOT NULL AND length(trim(body)) > 0)
    OR
    (message_type = 'GIF' AND (
      (gif_url IS NOT NULL AND length(trim(gif_url)) > 0)
      OR (gif_provider_id IS NOT NULL AND length(trim(gif_provider_id)) > 0)
    ))
  )
);

CREATE INDEX idx_chat_messages_tether_created ON chat_messages(tether_connection_id, created_at);
CREATE INDEX idx_chat_messages_reply_to ON chat_messages(reply_to_message_id);

CREATE TABLE chat_message_deletions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT uq_chat_message_deletions_user UNIQUE (message_id, user_id)
);

CREATE TABLE chat_message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reaction VARCHAR(8) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT uq_chat_message_reactions_user UNIQUE (message_id, user_id),
  CONSTRAINT chk_chat_message_reactions_supported CHECK (reaction IN ('❤️', '😂', '🥺', '😭', '🔥'))
);

CREATE TABLE chat_message_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT uq_chat_message_reads_user UNIQUE (message_id, user_id)
);

CREATE TABLE chat_presence_states (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  typing BOOLEAN NOT NULL DEFAULT false,
  typing_updated_at TIMESTAMPTZ,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by VARCHAR(255),
  updated_by VARCHAR(255),
  CONSTRAINT uq_chat_presence_states_user UNIQUE (tether_connection_id, user_id)
);
