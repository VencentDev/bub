package com.vencentdev.backend.modules.chat.repository;

import com.vencentdev.backend.modules.chat.entity.ChatMessageAttachment;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatMessageAttachmentRepository
    extends JpaRepository<ChatMessageAttachment, UUID> {

  List<ChatMessageAttachment> findByMessageIdInOrderByPositionAsc(List<UUID> messageIds);
}
