package com.vencentdev.backend.modules.tether.dto;

import java.time.Instant;
import java.util.UUID;

public record TetherInvitationResponse(UUID id, String code, Instant expiresAt, String qrPayload) {}
