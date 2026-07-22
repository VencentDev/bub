package com.vencentdev.backend.modules.notification.controller;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.auth.CurrentUser;
import com.vencentdev.backend.modules.notification.dto.NotificationListResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationReadAllResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationReadResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationSummaryResponse;
import com.vencentdev.backend.modules.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

  private final NotificationService notificationService;

  public NotificationController(NotificationService notificationService) {
    this.notificationService = notificationService;
  }

  @GetMapping("/summary")
  @Operation(operationId = "getNotificationSummary")
  public NotificationSummaryResponse summary(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return notificationService.summary(user);
  }

  @GetMapping
  @Operation(operationId = "listNotifications")
  public NotificationListResponse list(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @RequestParam(defaultValue = "20") int limit,
      @RequestParam(required = false) String cursor) {
    return notificationService.list(user, limit, cursor);
  }

  @PostMapping("/{notificationId}/read")
  @Operation(operationId = "markNotificationRead")
  public NotificationReadResponse markRead(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user,
      @PathVariable UUID notificationId) {
    return notificationService.markRead(user, notificationId);
  }

  @PostMapping("/read-all")
  @Operation(operationId = "markAllNotificationsRead")
  public NotificationReadAllResponse markAllRead(
      @Parameter(hidden = true) @CurrentUser AuthenticatedUser user) {
    return notificationService.markAllRead(user);
  }
}
