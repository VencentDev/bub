package com.vencentdev.backend.modules.bub.dto;

import java.time.Instant;
import java.util.UUID;

public record BubSendResponse(
    UUID bubId, UUID tetherConnectionId, UUID senderUserId, UUID receiverUserId, Instant sentAt) {}
