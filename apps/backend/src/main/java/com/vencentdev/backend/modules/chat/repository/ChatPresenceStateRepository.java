package com.vencentdev.backend.modules.chat.repository;

import com.vencentdev.backend.modules.chat.entity.ChatPresenceState;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatPresenceStateRepository extends JpaRepository<ChatPresenceState, UUID> {
  Optional<ChatPresenceState> findByTetherConnectionIdAndUserId(
      UUID tetherConnectionId, UUID userId);
}
