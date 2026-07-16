package com.vencentdev.backend.modules.user.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class PhoneValidator implements ConstraintValidator<Phone, String> {

  private static final String PHONE_PATTERN = "^\\+?[0-9 .()\\-]{7,30}$";

  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    return value == null || value.matches(PHONE_PATTERN);
  }
}
