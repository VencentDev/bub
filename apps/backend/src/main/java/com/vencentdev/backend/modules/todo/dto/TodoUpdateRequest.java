package com.vencentdev.backend.modules.todo.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonCreator.Mode;
import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import org.openapitools.jackson.nullable.JsonNullable;
import tools.jackson.databind.JsonNode;

public record TodoUpdateRequest(
    @Size(max = 200) JsonNullable<String> title,
    @Size(max = 5000) JsonNullable<String> description,
    JsonNullable<TodoStatus> status,
    JsonNullable<LocalDate> dueDate) {

  @JsonCreator(mode = Mode.DELEGATING)
  public static TodoUpdateRequest fromJson(JsonNode node) {
    return new TodoUpdateRequest(
        nullableString(node, "title"),
        nullableString(node, "description"),
        nullableStatus(node, "status"),
        nullableDate(node, "dueDate"));
  }

  private static JsonNullable<String> nullableString(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : value.asText());
  }

  private static JsonNullable<TodoStatus> nullableStatus(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : TodoStatus.valueOf(value.asText()));
  }

  private static JsonNullable<LocalDate> nullableDate(JsonNode node, String field) {
    if (node == null || !node.has(field)) {
      return JsonNullable.undefined();
    }

    JsonNode value = node.get(field);
    return JsonNullable.of(value.isNull() ? null : LocalDate.parse(value.asText()));
  }
}
