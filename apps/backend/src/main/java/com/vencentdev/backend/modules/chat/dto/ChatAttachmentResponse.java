package com.vencentdev.backend.modules.chat.dto;

import com.vencentdev.backend.modules.chat.entity.ChatAttachmentType;
import java.util.UUID;

public record ChatAttachmentResponse(
    UUID id,
    ChatAttachmentType type,
    String url,
    String contentType,
    long sizeBytes,
    int position) {}
