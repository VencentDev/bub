package com.vencentdev.backend.modules.notification.dto;

public record NotificationSummaryResponse(long unreadCount, NotificationItemResponse latest) {}
