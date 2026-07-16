package com.vencentdev.backend.modules.todo.repository;

import com.vencentdev.backend.modules.todo.entity.Todo;
import com.vencentdev.backend.modules.todo.enums.TodoStatus;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, UUID> {

  Page<Todo> findByOwnerId(UUID ownerId, Pageable pageable);

  Page<Todo> findByOwnerIdAndStatus(UUID ownerId, TodoStatus status, Pageable pageable);

  Optional<Todo> findByIdAndOwnerId(UUID id, UUID ownerId);
}
