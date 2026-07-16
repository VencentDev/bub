package com.vencentdev.backend.modules.todo.mapper;

import com.vencentdev.backend.modules.todo.dto.TodoCreateRequest;
import com.vencentdev.backend.modules.todo.dto.TodoResponse;
import com.vencentdev.backend.modules.todo.dto.TodoUpdateRequest;
import com.vencentdev.backend.modules.todo.entity.Todo;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public abstract class TodoMapper {

  public abstract TodoResponse toResponse(Todo todo);

  @Mapping(target = "id", ignore = true)
  @Mapping(target = "ownerId", ignore = true)
  public abstract Todo fromCreate(TodoCreateRequest request);

  public void applyUpdate(TodoUpdateRequest request, Todo target) {
    if (request.title() != null && request.title().isPresent()) {
      target.setTitle(request.title().get());
    }
    if (request.description() != null && request.description().isPresent()) {
      target.setDescription(request.description().get());
    }
    if (request.status() != null && request.status().isPresent()) {
      target.setStatus(request.status().get());
    }
    if (request.dueDate() != null && request.dueDate().isPresent()) {
      target.setDueDate(request.dueDate().get());
    }
  }
}
