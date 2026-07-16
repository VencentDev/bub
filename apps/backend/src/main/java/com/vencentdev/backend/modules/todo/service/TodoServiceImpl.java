package com.vencentdev.backend.modules.todo.service;

import com.vencentdev.backend.common.exception.ForbiddenException;
import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.todo.dto.PageResponse;
import com.vencentdev.backend.modules.todo.dto.TodoCreateRequest;
import com.vencentdev.backend.modules.todo.dto.TodoResponse;
import com.vencentdev.backend.modules.todo.dto.TodoUpdateRequest;
import com.vencentdev.backend.modules.todo.entity.Todo;
import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import com.vencentdev.backend.modules.todo.mapper.TodoMapper;
import com.vencentdev.backend.modules.todo.repository.TodoRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TodoServiceImpl implements TodoService {

  private final TodoRepository repository;
  private final TodoMapper mapper;
  private final UserService users;

  public TodoServiceImpl(TodoRepository repository, TodoMapper mapper, UserService users) {
    this.repository = repository;
    this.mapper = mapper;
    this.users = users;
  }

  @Override
  @Transactional
  public PageResponse<TodoResponse> list(
      AuthenticatedUser principal, TodoStatus status, Pageable pageable) {
    UUID ownerId = users.resolveInternalId(principal);
    Page<TodoResponse> page =
        (status == null
                ? repository.findByOwnerId(ownerId, pageable)
                : repository.findByOwnerIdAndStatus(ownerId, status, pageable))
            .map(mapper::toResponse);
    return PageResponse.from(page);
  }

  @Override
  @Transactional
  public TodoResponse create(AuthenticatedUser principal, TodoCreateRequest request) {
    UUID ownerId = users.resolveInternalId(principal);
    Todo todo = mapper.fromCreate(request);
    todo.setOwnerId(ownerId);
    return mapper.toResponse(repository.save(todo));
  }

  @Override
  @Transactional
  public TodoResponse get(AuthenticatedUser principal, UUID id) {
    UUID ownerId = users.resolveInternalId(principal);
    return repository
        .findByIdAndOwnerId(id, ownerId)
        .map(mapper::toResponse)
        .orElseThrow(() -> new ResourceNotFoundException("Todo not found"));
  }

  @Override
  @Transactional
  public TodoResponse update(AuthenticatedUser principal, UUID id, TodoUpdateRequest request) {
    UUID ownerId = users.resolveInternalId(principal);
    Todo todo =
        repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Todo not found"));
    if (!todo.getOwnerId().equals(ownerId)) {
      throw new ForbiddenException("Not your todo");
    }
    mapper.applyUpdate(request, todo);
    return mapper.toResponse(todo);
  }

  @Override
  @Transactional
  public void delete(AuthenticatedUser principal, UUID id) {
    UUID ownerId = users.resolveInternalId(principal);
    Todo todo =
        repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Todo not found"));
    if (!todo.getOwnerId().equals(ownerId)) {
      throw new ForbiddenException("Not your todo");
    }
    repository.delete(todo);
  }
}
