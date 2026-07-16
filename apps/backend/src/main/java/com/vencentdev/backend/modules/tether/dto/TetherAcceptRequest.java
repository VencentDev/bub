package com.vencentdev.backend.modules.tether.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record TetherAcceptRequest(
    @NotBlank @Pattern(regexp = "^BUB-[A-Z0-9]{4}-[A-Z0-9]{4}$") String code) {}
