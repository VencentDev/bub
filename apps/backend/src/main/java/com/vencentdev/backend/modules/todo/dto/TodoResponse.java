package com.vencentdev.backend.modules.todo.dto;

import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record TodoResponse(
    UUID id,
    String title,
    String description,
    TodoStatus status,
    LocalDate dueDate,
    Instant createdAt,
    Instant updatedAt) {}
