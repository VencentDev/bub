package com.vencentdev.backend.modules.safe.dto;

import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import java.time.Instant;
import java.util.UUID;

public record SafeChatNoticeResponse(
    UUID id, ChatMessageType type, Integer safeItemCount, UUID senderUserId, Instant createdAt) {}
