package com.vencentdev.backend.modules.chat.repository;

import com.vencentdev.backend.modules.chat.entity.ChatMessageDeletion;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatMessageDeletionRepository extends JpaRepository<ChatMessageDeletion, UUID> {
  Optional<ChatMessageDeletion> findByMessageIdAndUserId(UUID messageId, UUID userId);
}
