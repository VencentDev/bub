package com.vencentdev.backend.modules.chat.dto;

import com.vencentdev.backend.modules.chat.entity.ChatMessageType;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ChatMessageResponse(
    UUID id,
    UUID senderUserId,
    boolean viewerMessage,
    ChatMessageType type,
    String body,
    String gifUrl,
    String gifProviderId,
    ChatReplyPreviewResponse reply,
    Instant createdAt,
    Instant updatedAt,
    Instant editedAt,
    boolean deletedForEveryone,
    ChatDeliveryState deliveryState,
    boolean editable,
    boolean deletableForEveryone,
    String viewerReaction,
    List<ChatReactionSummaryResponse> reactions) {}
