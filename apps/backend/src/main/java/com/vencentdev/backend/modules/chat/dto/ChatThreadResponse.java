package com.vencentdev.backend.modules.chat.dto;

import java.util.List;
import java.util.UUID;

public record ChatThreadResponse(
    boolean hasActiveTether,
    UUID tetherConnectionId,
    String partnerDisplayName,
    ChatStateResponse state,
    List<ChatMessageResponse> messages) {}
