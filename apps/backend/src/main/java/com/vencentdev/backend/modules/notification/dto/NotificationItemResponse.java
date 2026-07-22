package com.vencentdev.backend.modules.notification.dto;

import com.vencentdev.backend.modules.notification.entity.NotificationCategory;
import java.time.Instant;
import java.util.UUID;

public record NotificationItemResponse(
    UUID id,
    NotificationCategory category,
    String title,
    String body,
    String linkPath,
    Instant readAt,
    Instant createdAt) {}
