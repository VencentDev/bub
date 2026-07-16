package com.vencentdev.backend.common.exception;

import java.time.Instant;
import java.util.List;

public record ApiError(
    int status,
    String code,
    String message,
    String traceId,
    Instant timestamp,
    List<FieldError> errors) {
  public record FieldError(String field, String message) {}
}
