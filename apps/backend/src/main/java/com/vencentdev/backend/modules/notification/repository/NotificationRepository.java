package com.vencentdev.backend.modules.notification.repository;

import com.vencentdev.backend.modules.notification.entity.Notification;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

  long countByRecipientUserIdAndReadAtIsNull(UUID recipientUserId);

  Optional<Notification> findFirstByRecipientUserIdOrderByCreatedAtDescIdDesc(UUID recipientUserId);

  Optional<Notification> findByIdAndRecipientUserId(UUID id, UUID recipientUserId);

  @Query(
      """
      select notification
      from Notification notification
      where notification.recipientUser.id = :recipientUserId
      order by notification.createdAt desc, notification.id desc
      """)
  List<Notification> findRecent(@Param("recipientUserId") UUID recipientUserId, Pageable pageable);

  @Query(
      """
      select notification
      from Notification notification
      where notification.recipientUser.id = :recipientUserId
        and (
          notification.createdAt < :createdAt
          or (notification.createdAt = :createdAt and notification.id < :id)
        )
      order by notification.createdAt desc, notification.id desc
      """)
  List<Notification> findAfterCursor(
      @Param("recipientUserId") UUID recipientUserId,
      @Param("createdAt") Instant createdAt,
      @Param("id") UUID id,
      Pageable pageable);

  @Modifying
  @Query(
      """
      update Notification notification
      set notification.readAt = :readAt
      where notification.recipientUser.id = :recipientUserId
        and notification.readAt is null
      """)
  int markAllRead(@Param("recipientUserId") UUID recipientUserId, @Param("readAt") Instant readAt);
}
