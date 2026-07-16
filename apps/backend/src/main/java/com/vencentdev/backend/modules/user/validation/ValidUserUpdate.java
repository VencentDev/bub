package com.vencentdev.backend.modules.user.validation;

import static java.lang.annotation.ElementType.TYPE;
import static java.lang.annotation.RetentionPolicy.RUNTIME;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;
import java.lang.annotation.Retention;
import java.lang.annotation.Target;

@Target(TYPE)
@Retention(RUNTIME)
@Constraint(validatedBy = UserValidator.class)
public @interface ValidUserUpdate {
  String message() default "invalid user update";

  Class<?>[] groups() default {};

  Class<? extends Payload>[] payload() default {};
}
