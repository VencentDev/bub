package com.vencentdev.backend.modules.todo.dto;

import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record TodoCreateRequest(
    @NotBlank @Size(max = 200) String title,
    @Size(max = 5000) String description,
    @NotNull TodoStatus status,
    LocalDate dueDate) {}
