package com.vencentdev.backend.modules.chat.dto;

import java.util.UUID;

public record ChatReplyPreviewResponse(
    UUID id, UUID senderUserId, String snippet, boolean deletedForEveryone) {}
