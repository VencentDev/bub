package com.vencentdev.backend.modules.legal.dto;

import java.time.LocalDate;

public record LegalPolicyResponse(
    String slug, String title, String version, LocalDate effectiveDate, String body) {}
