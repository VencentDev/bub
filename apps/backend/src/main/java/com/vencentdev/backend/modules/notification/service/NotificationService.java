package com.vencentdev.backend.modules.notification.service;

import com.vencentdev.backend.modules.auth.AuthenticatedUser;
import com.vencentdev.backend.modules.notification.dto.NotificationListResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationReadAllResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationReadResponse;
import com.vencentdev.backend.modules.notification.dto.NotificationSummaryResponse;
import java.util.UUID;

public interface NotificationService {

  NotificationSummaryResponse summary(AuthenticatedUser principal);

  NotificationListResponse list(AuthenticatedUser principal, int limit, String cursor);

  NotificationReadResponse markRead(AuthenticatedUser principal, UUID notificationId);

  NotificationReadAllResponse markAllRead(AuthenticatedUser principal);
}
