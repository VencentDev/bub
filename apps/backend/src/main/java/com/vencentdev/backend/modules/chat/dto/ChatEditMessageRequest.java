package com.vencentdev.backend.modules.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChatEditMessageRequest(
    @NotBlank(message = "Body is required") @Size(max = 4000) String body) {}
