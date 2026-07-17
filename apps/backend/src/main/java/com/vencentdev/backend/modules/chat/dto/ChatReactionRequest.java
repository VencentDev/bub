package com.vencentdev.backend.modules.chat.dto;

import jakarta.validation.constraints.NotBlank;

public record ChatReactionRequest(@NotBlank String reaction) {}
