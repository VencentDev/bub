package com.vencentdev.backend.modules.user.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.net.URI;

public class UrlValidator implements ConstraintValidator<Url, String> {

  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    if (value == null || value.isBlank()) {
      return true;
    }

    try {
      URI uri = URI.create(value);
      return uri.getScheme() != null
          && uri.getHost() != null
          && (uri.getScheme().equals("http") || uri.getScheme().equals("https"));
    } catch (IllegalArgumentException exception) {
      return false;
    }
  }
}
