package com.vencentdev.backend.modules.tether.repository;

import com.vencentdev.backend.modules.tether.entity.TetherConnection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TetherConnectionRepository extends JpaRepository<TetherConnection, UUID> {

  @Query(
      """
      select connection
      from TetherConnection connection
      join fetch connection.userOne
      join fetch connection.userTwo
      where connection.active = true
        and (connection.userOne.id = :userId or connection.userTwo.id = :userId)
      """)
  Optional<TetherConnection> findActiveByUserId(@Param("userId") UUID userId);

  @Query(
      """
      select count(connection) > 0
      from TetherConnection connection
      where connection.active = true
        and (connection.userOne.id = :userId or connection.userTwo.id = :userId)
      """)
  boolean existsActiveByUserId(@Param("userId") UUID userId);
}
