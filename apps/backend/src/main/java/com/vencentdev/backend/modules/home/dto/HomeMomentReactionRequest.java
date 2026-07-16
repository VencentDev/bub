package com.vencentdev.backend.modules.home.dto;

import jakarta.validation.constraints.NotBlank;

public record HomeMomentReactionRequest(@NotBlank String reaction) {}
