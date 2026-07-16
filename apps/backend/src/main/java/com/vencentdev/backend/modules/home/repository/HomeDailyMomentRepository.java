package com.vencentdev.backend.modules.home.repository;

import com.vencentdev.backend.modules.home.entity.HomeDailyMoment;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface HomeDailyMomentRepository extends JpaRepository<HomeDailyMoment, UUID> {

  @Query(
      """
      select moment
      from HomeDailyMoment moment
      join fetch moment.tetherConnection connection
      join fetch moment.createdByUser
      where connection.id = :tetherConnectionId
        and moment.localDate = :localDate
      """)
  Optional<HomeDailyMoment> findByTetherConnectionIdAndLocalDate(
      @Param("tetherConnectionId") UUID tetherConnectionId,
      @Param("localDate") LocalDate localDate);

  @Query(
      """
      select moment
      from HomeDailyMoment moment
      join fetch moment.tetherConnection connection
      join fetch moment.createdByUser
      join fetch connection.userOne
      join fetch connection.userTwo
      where moment.id = :id
      """)
  Optional<HomeDailyMoment> findByIdWithTetherAndUsers(@Param("id") UUID id);
}
