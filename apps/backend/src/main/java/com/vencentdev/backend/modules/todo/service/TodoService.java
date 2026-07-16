package com.vencentdev.backend.modules.todo.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.todo.dto.PageResponse;
import com.vencentdev.backend.modules.todo.dto.TodoCreateRequest;
import com.vencentdev.backend.modules.todo.dto.TodoResponse;
import com.vencentdev.backend.modules.todo.dto.TodoUpdateRequest;
import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import java.util.UUID;
import org.springframework.data.domain.Pageable;

public interface TodoService {

  PageResponse<TodoResponse> list(
      AuthenticatedUser principal, TodoStatus status, Pageable pageable);

  TodoResponse create(AuthenticatedUser principal, TodoCreateRequest request);

  TodoResponse get(AuthenticatedUser principal, UUID id);

  TodoResponse update(AuthenticatedUser principal, UUID id, TodoUpdateRequest request);

  void delete(AuthenticatedUser principal, UUID id);
}
