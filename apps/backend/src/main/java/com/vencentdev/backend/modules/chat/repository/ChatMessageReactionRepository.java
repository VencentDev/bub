package com.vencentdev.backend.modules.chat.repository;

import com.vencentdev.backend.modules.chat.entity.ChatMessageReaction;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatMessageReactionRepository extends JpaRepository<ChatMessageReaction, UUID> {
  List<ChatMessageReaction> findByMessageIdIn(List<UUID> messageIds);

  List<ChatMessageReaction> findByMessageId(UUID messageId);

  Optional<ChatMessageReaction> findByMessageIdAndUserId(UUID messageId, UUID userId);
}
