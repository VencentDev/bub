package com.vencentdev.backend.modules.notification.dto;

import java.util.UUID;

public record NotificationReadResponse(UUID id, boolean read) {}
