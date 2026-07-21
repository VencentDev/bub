package com.vencentdev.backend.modules.safe.dto;

import com.vencentdev.backend.modules.safe.entity.SafeMediaType;
import java.time.Instant;
import java.util.UUID;

public record SafeMediaItemResponse(
    UUID id,
    SafeMediaType type,
    String url,
    String contentType,
    long sizeBytes,
    String originalFilename,
    UUID uploadedByUserId,
    Instant createdAt) {}
