package com.vencentdev.backend.modules.tether.repository;

import com.vencentdev.backend.modules.tether.entity.TetherInvitation;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface TetherInvitationRepository extends JpaRepository<TetherInvitation, UUID> {

  Optional<TetherInvitation> findByCode(String code);

  boolean existsByCode(String code);

  @Query(
      """
      select invitation
      from TetherInvitation invitation
      join fetch invitation.creator
      left join fetch invitation.acceptedUser
      where invitation.code = :code
      """)
  Optional<TetherInvitation> findByCodeWithUsers(String code);
}
