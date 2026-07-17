package com.vencentdev.backend.modules.chat.dto;

import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ChatSendMessageRequest(
    @NotNull ChatMessageType type,
    String body,
    String gifUrl,
    String gifProviderId,
    UUID replyToMessageId) {}
