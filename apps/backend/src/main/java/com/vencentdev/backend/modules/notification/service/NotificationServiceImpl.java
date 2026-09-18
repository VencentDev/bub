package com.vencentdev.backend.modules.notification.service;

import com.vencentdev.backend.common.exception.ResourceNotFoundException;
import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.notification.dto.NotificationItemResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationListResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationReadAllResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationReadResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationSummaryResponse;
import com.vencentdev.backend.modules.notification.entity.Notification;
import com.vencentdev.backend.modules.notification.repository.NotificationRepository;
import com.vencentdev.backend.modules.user.service.UserService;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationServiceImpl implements NotificationService {
  private static final int DEFAULT_LIMIT = 20;
  private static final int MAX_LIMIT = 100;

  private final NotificationRepository notifications;
  private final UserService userService;

  public NotificationServiceImpl(NotificationRepository notifications, UserService userService) {
    this.notifications = notifications;
    this.userService = userService;
  }

  @Override
  @Transactional(readOnly = true)
  public NotificationSummaryResponse summary(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    long unreadCount = notifications.countByRecipientUserIdAndReadAtIsNull(userId);
    NotificationItemResponse latest =
        notifications
            .findFirstByRecipientUserIdOrderByCreatedAtDescIdDesc(userId)
            .map(this::toItem)
            .orElse(null);
    return new NotificationSummaryResponse(unreadCount, latest);
  }

  @Override
  @Transactional(readOnly = true)
  public NotificationListResponse list(AuthenticatedUser principal, int limit, String cursor) {
    UUID userId = userService.resolveInternalId(principal);
    int requestedLimit = normalizedLimit(limit);
    PageRequest page = PageRequest.of(0, requestedLimit + 1);
    List<Notification> rows =
        cursor == null || cursor.isBlank()
            ? notifications.findRecent(userId, page)
            : findAfterCursor(userId, cursor, page);
    boolean hasMore = rows.size() > requestedLimit;
    List<Notification> visibleRows = hasMore ? rows.subList(0, requestedLimit) : rows;
    String nextCursor = hasMore ? cursorFor(visibleRows.getLast()) : null;
    return new NotificationListResponse(
        visibleRows.stream().map(this::toItem).toList(), nextCursor, hasMore);
  }

  @Override
  @Transactional
  public NotificationReadResponse markRead(AuthenticatedUser principal, UUID notificationId) {
    UUID userId = userService.resolveInternalId(principal);
    Notification notification =
        notifications
            .findByIdAndRecipientUserId(notificationId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
    if (notification.getReadAt() == null) {
      notification.setReadAt(Instant.now());
    }
    return new NotificationReadResponse(notification.getId(), true);
  }

  @Override
  @Transactional
  public NotificationReadAllResponse markAllRead(AuthenticatedUser principal) {
    UUID userId = userService.resolveInternalId(principal);
    int updatedCount = notifications.markAllRead(userId, Instant.now());
    return new NotificationReadAllResponse(updatedCount);
  }

  private List<Notification> findAfterCursor(UUID userId, String cursor, PageRequest page) {
    Cursor decoded = decodeCursor(cursor);
    return notifications.findAfterCursor(userId, decoded.createdAt(), decoded.id(), page);
  }

  private int normalizedLimit(int limit) {
    if (limit <= 0) {
      return DEFAULT_LIMIT;
    }
    return Math.min(limit, MAX_LIMIT);
  }

  private String cursorFor(Notification notification) {
    String value = notification.getCreatedAt() + "|" + notification.getId();
    return Base64.getUrlEncoder()
        .withoutPadding()
        .encodeToString(value.getBytes(StandardCharsets.UTF_8));
  }

  private Cursor decodeCursor(String cursor) {
    try {
      String decoded = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8);
      String[] parts = decoded.split("\\|", 2);
      return new Cursor(Instant.parse(parts[0]), UUID.fromString(parts[1]));
    } catch (DateTimeParseException
        | IllegalArgumentException
        | ArrayIndexOutOfBoundsException ex) {
      throw new ResourceNotFoundException("Notification cursor not found");
    }
  }

  private NotificationItemResponse toItem(Notification notification) {
    return new NotificationItemResponse(
        notification.getId(),
        notification.getCategory(),
        notification.getTitle(),
        notification.getBody(),
        notification.getLinkPath(),
        notification.getReadAt(),
        notification.getCreatedAt());
  }

  private record Cursor(Instant createdAt, UUID id) {}
}
