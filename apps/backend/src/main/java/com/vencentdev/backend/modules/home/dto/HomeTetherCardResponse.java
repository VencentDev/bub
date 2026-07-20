package com.vencentdev.backend.modules.home.dto;

import java.time.Instant;
import java.util.UUID;

public record HomeTetherCardResponse(
    boolean hasActiveTether,
    UUID partnerUserId,
    String partnerDisplayName,
    String partnerProfileImageUrl,
    String viewerProfileImageUrl,
    String viewerMood,
    String partnerMood,
    Instant tetheredSince,
    String ctaLabel) {}
