package com.vencentdev.backend.modules.user.validation;

import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class UserValidator implements ConstraintValidator<ValidUserUpdate, UserUpdateRequest> {

  @Override
  public boolean isValid(UserUpdateRequest value, ConstraintValidatorContext context) {
    if (value == null) {
      return true;
    }

    boolean valid = true;
    context.disableDefaultConstraintViolation();

    if (value.age() != null && value.age().isPresent()) {
      Integer age = value.age().get();
      if (age != null && (age < 13 || age > 120)) {
        context
            .buildConstraintViolationWithTemplate("age must be between 13 and 120")
            .addPropertyNode("age")
            .addConstraintViolation();
        valid = false;
      }
    }

    if (value.discoveredAppVia() != null && value.discoveredAppVia().isPresent()) {
      String source = value.discoveredAppVia().get();
      if (source != null && !source.matches("tiktok|playstore|recommendation|others")) {
        context
            .buildConstraintViolationWithTemplate("discoveredAppVia is unsupported")
            .addPropertyNode("discoveredAppVia")
            .addConstraintViolation();
        valid = false;
      }
    }

    if (value.relationshipStatus() != null && value.relationshipStatus().isPresent()) {
      String status = value.relationshipStatus().get();
      if (status != null && !status.matches("dating|engaged|married|long_distance")) {
        context
            .buildConstraintViolationWithTemplate("relationshipStatus is unsupported")
            .addPropertyNode("relationshipStatus")
            .addConstraintViolation();
        valid = false;
      }
    }

    if (value.relationshipLength() != null && value.relationshipLength().isPresent()) {
      String length = value.relationshipLength().get();
      if (length != null
          && !length.matches("under_3_months|3_to_12_months|1_to_3_years|3_plus_years")) {
        context
            .buildConstraintViolationWithTemplate("relationshipLength is unsupported")
            .addPropertyNode("relationshipLength")
            .addConstraintViolation();
        valid = false;
      }
    }

    if (value.termsAccepted() != null
        && value.termsAccepted().isPresent()
        && !Boolean.TRUE.equals(value.termsAccepted().get())) {
      context
          .buildConstraintViolationWithTemplate("termsAccepted must be true when present")
          .addPropertyNode("termsAccepted")
          .addConstraintViolation();
      valid = false;
    }

    return valid;
  }
}
