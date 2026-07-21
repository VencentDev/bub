package com.vencentdev.backend.modules.safe.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record SafeUnlockRequest(
    @NotBlank(message = "Safe PIN is required")
        @Pattern(regexp = "\\d{4,6}", message = "Safe PIN must be 4 to 6 digits")
        String pin) {}
