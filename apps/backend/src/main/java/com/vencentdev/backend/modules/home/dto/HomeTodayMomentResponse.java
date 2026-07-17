package com.vencentdev.backend.modules.home.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record HomeTodayMomentResponse(
    UUID momentId,
    String photoUrl,
    String viewerPhotoUrl,
    Instant partnerCapturedAt,
    LocalDate localDate,
    boolean viewerHasPostedToday,
    String partnerReaction) {}
