package com.vencentdev.backend.modules.chat.dto;

import java.time.Instant;

public record ChatPresenceResponse(ChatPresenceStatus status, Instant lastSeenAt) {}
