package com.vencentdev.backend.modules.tether.dto;

import java.util.UUID;

public record TetherStatusResponse(boolean hasActiveTether, UUID partnerUserId) {}
