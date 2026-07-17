package com.vencentdev.backend.modules.home.repository;

import com.vencentdev.backend.modules.home.entity.HomeMood;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HomeMoodRepository extends JpaRepository<HomeMood, UUID> {

  Optional<HomeMood> findByUserId(UUID userId);
}
