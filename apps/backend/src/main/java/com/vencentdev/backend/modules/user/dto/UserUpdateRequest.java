package com.vencentdev.backend.modules.user.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonCreator.Mode;
import com.vencentdev.backend.modules.user.validation.ValidUserUpdate;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import org.openapitools.jackson.nullable.JsonNullable;
import tools.jackson.databind.JsonNode;

@ValidUserUpdate
public record UserUpdateRequest(
    @Email JsonNullable<String> email, @Size(max = 120) JsonNullable<String> displayName) {

  @JsonCreator(mode = Mode.DELEGATING)
  public static UserUpdateRequest fromJson(JsonNode node) {
    return new UserUpdateRequest(
        nullableString(node, "email"), nullableString(node, "displayName"));
  }

  private static JsonNullable<String> nullableString(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : value.asText());
  }
}
