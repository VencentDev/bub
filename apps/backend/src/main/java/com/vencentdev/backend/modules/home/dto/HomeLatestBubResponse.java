package com.vencentdev.backend.modules.home.dto;

import java.time.Instant;

public record HomeLatestBubResponse(
    boolean hasActivity,
    String copy,
    Instant occurredAt,
    Instant viewerLastSentAt,
    Instant partnerLastSentAt,
    String viewerLastSentCopy,
    String partnerLastSentCopy,
    int streakDays) {}
