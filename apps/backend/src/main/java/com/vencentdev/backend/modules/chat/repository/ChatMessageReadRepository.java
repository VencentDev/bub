package com.vencentdev.backend.modules.chat.repository;

import com.vencentdev.backend.modules.chat.entity.ChatMessageRead;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatMessageReadRepository extends JpaRepository<ChatMessageRead, UUID> {
  List<ChatMessageRead> findByMessageIdIn(List<UUID> messageIds);

  Optional<ChatMessageRead> findByMessageIdAndUserId(UUID messageId, UUID userId);
}
