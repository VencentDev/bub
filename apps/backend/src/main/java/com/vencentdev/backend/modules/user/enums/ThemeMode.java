package com.vencentdev.backend.modules.user.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum ThemeMode {
  SYSTEM("system"),
  LIGHT("light"),
  DARK("dark");

  private final String value;

  ThemeMode(String value) {
    this.value = value;
  }

  @JsonCreator
  public static ThemeMode fromJson(String value) {
    for (ThemeMode mode : values()) {
      if (mode.value.equals(value)) {
        return mode;
      }
    }
    throw new IllegalArgumentException("Unsupported theme mode");
  }

  @JsonValue
  public String value() {
    return value;
  }
}
