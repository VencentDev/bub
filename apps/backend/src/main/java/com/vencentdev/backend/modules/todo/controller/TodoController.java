package com.vencentdev.backend.modules.todo.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.todo.dto.PageResponse;
import com.vencentdev.backend.modules.todo.dto.TodoCreateRequest;
import com.vencentdev.backend.modules.todo.dto.TodoResponse;
import com.vencentdev.backend.modules.todo.dto.TodoUpdateRequest;
import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import com.vencentdev.backend.modules.todo.service.TodoService;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/todos")
public class TodoController {

  private final TodoService todos;

  public TodoController(TodoService todos) {
    this.todos = todos;
  }

  @GetMapping
  public PageResponse<TodoResponse> list(
      @CurrentUser AuthenticatedUser user,
      @RequestParam(required = false) TodoStatus status,
      @PageableDefault(size = 20, sort = "dueDate") Pageable pageable) {
    return todos.list(user, status, pageable);
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public TodoResponse create(
      @CurrentUser AuthenticatedUser user, @Valid @RequestBody TodoCreateRequest request) {
    return todos.create(user, request);
  }

  @GetMapping("/{id}")
  public TodoResponse get(@CurrentUser AuthenticatedUser user, @PathVariable UUID id) {
    return todos.get(user, id);
  }

  @PatchMapping("/{id}")
  public TodoResponse update(
      @CurrentUser AuthenticatedUser user,
      @PathVariable UUID id,
      @Valid @RequestBody TodoUpdateRequest request) {
    return todos.update(user, id, request);
  }

  @DeleteMapping("/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@CurrentUser AuthenticatedUser user, @PathVariable UUID id) {
    todos.delete(user, id);
  }
}
