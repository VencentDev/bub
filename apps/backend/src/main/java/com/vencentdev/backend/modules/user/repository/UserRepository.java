package com.vencentdev.backend.modules.user.repository;

import com.vencentdev.backend.modules.user.entity.User;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, UUID> {
  Optional<User> findByExternalId(String externalId);

  boolean existsByEmail(String email);
}
