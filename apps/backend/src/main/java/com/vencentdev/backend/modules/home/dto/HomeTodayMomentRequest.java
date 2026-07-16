package com.vencentdev.backend.modules.home.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record HomeTodayMomentRequest(@NotBlank String photoUrl, @NotNull LocalDate localDate) {}
