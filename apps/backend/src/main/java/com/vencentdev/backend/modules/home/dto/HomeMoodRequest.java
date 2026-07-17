package com.vencentdev.backend.modules.home.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record HomeMoodRequest(@NotBlank @Size(max = 20) String mood) {}
