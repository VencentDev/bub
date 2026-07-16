package com.vencentdev.backend.modules.user.validation;

import com.vencentdev.backend.modules.user.dto.UserUpdateRequest;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class UserValidator implements ConstraintValidator<ValidUserUpdate, UserUpdateRequest> {

  @Override
  public boolean isValid(UserUpdateRequest value, ConstraintValidatorContext context) {
    return true;
  }
}
