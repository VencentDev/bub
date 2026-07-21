package com.vencentdev.backend.modules.safe.repository;

import com.vencentdev.backend.modules.safe.entity.SafeVaultAccess;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SafeVaultAccessRepository extends JpaRepository<SafeVaultAccess, UUID> {

  Optional<SafeVaultAccess> findByTetherConnectionIdAndUserId(UUID tetherConnectionId, UUID userId);

  boolean existsByTetherConnectionIdAndUserId(UUID tetherConnectionId, UUID userId);
}
