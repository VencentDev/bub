package com.vencentdev.backend.modules.safe.repository;

import com.vencentdev.backend.modules.safe.entity.SafeMediaItem;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SafeMediaItemRepository extends JpaRepository<SafeMediaItem, UUID> {

  List<SafeMediaItem> findByTetherConnectionIdAndDeletedAtIsNullOrderByCreatedAtDescIdDesc(
      UUID tetherConnectionId);

  Optional<SafeMediaItem> findByIdAndTetherConnectionId(UUID id, UUID tetherConnectionId);
}
