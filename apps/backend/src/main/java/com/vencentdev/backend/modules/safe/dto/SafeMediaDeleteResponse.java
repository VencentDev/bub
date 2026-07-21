package com.vencentdev.backend.modules.safe.dto;

import java.util.UUID;

public record SafeMediaDeleteResponse(UUID id, boolean deleted) {}
