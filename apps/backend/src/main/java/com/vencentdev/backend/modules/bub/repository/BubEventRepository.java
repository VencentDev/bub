package com.vencentdev.backend.modules.bub.repository;

import com.vencentdev.backend.modules.bub.entity.BubEvent;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BubEventRepository extends JpaRepository<BubEvent, UUID> {

  Optional<BubEvent> findFirstByTetherConnectionIdAndSenderUserIdOrderByCreatedAtDescIdDesc(
      UUID connectionId, UUID senderUserId);

  List<BubEvent> findByTetherConnectionIdOrderByCreatedAtDescIdDesc(UUID connectionId);
}
