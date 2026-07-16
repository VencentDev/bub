package com.vencentdev.backend.modules.home.dto;

import java.time.Instant;

public record HomeLatestBubResponse(boolean hasActivity, String copy, Instant occurredAt) {}
