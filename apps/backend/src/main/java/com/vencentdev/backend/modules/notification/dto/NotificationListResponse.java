package com.vencentdev.backend.modules.notification.dto;

import java.util.List;

public record NotificationListResponse(
    List<NotificationItemResponse> items, String nextCursor, boolean hasMore) {}
