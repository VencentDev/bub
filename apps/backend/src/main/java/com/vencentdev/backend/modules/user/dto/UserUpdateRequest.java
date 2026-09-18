package com.vencentdev.backend.modules.user.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonCreator.Mode;
import com.vencentdev.backend.modules.user.enums.ThemeMode;
import com.vencentdev.backend.modules.user.validation.ValidUserUpdate;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.openapitools.jackson.nullable.JsonNullable;
import tools.jackson.databind.JsonNode;

@ValidUserUpdate
public record UserUpdateRequest(
    @Email JsonNullable<String> email,
    @Size(max = 120) JsonNullable<String> displayName,
    JsonNullable<ThemeMode> themeMode,
    @Pattern(regexp = "en|fil") JsonNullable<String> language,
    @Min(13) @Max(120) JsonNullable<Integer> age,
    @Pattern(regexp = "tiktok|playstore|recommendation|others")
        JsonNullable<String> discoveredAppVia,
    @Pattern(regexp = "dating|engaged|married|long_distance")
        JsonNullable<String> relationshipStatus,
    @Pattern(regexp = "under_3_months|3_to_12_months|1_to_3_years|3_plus_years")
        JsonNullable<String> relationshipLength,
    JsonNullable<Boolean> termsAccepted) {

  @JsonCreator(mode = Mode.DELEGATING)
  public static UserUpdateRequest fromJson(JsonNode node) {
    return new UserUpdateRequest(
        nullableString(node, "email"),
        nullableString(node, "displayName"),
        nullableThemeMode(node, "themeMode"),
        nullableString(node, "language"),
        nullableInteger(node, "age"),
        nullableString(node, "discoveredAppVia"),
        nullableString(node, "relationshipStatus"),
        nullableString(node, "relationshipLength"),
        nullableBoolean(node, "termsAccepted"));
  }

  private static JsonNullable<String> nullableString(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : value.asText());
  }

  private static JsonNullable<ThemeMode> nullableThemeMode(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : ThemeMode.fromJson(value.asText()));
  }

  private static JsonNullable<Integer> nullableInteger(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : value.asInt());
  }

  private static JsonNullable<Boolean> nullableBoolean(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : value.asBoolean());
  }
}
