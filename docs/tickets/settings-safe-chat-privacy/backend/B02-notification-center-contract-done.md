# B02 Notification Center Contract

## Goal

Add a backend notification center contract for the top-nav notification icon, unread badge, and notification list.

## Files To Create Or Modify

- Create or modify notification module files under `apps/backend/src/main/java/com/vencentdev/backend/modules/notification/`
- Create `Notification` entity if one does not already exist.
- Create `NotificationRepository`.
- Create `NotificationController`.
- Create `NotificationService`.
- Create DTOs for notification summary, list item, mark-read request, and unread count response.
- Test `apps/backend/src/test/java/com/vencentdev/backend/modules/notification/NotificationControllerIntegrationTest.java`

## Requirements

- Add `GET /api/v1/notifications/summary` returning unread count and latest notification preview.
- Add `GET /api/v1/notifications?limit=20&cursor=...` returning newest notifications first.
- Add `POST /api/v1/notifications/{id}/read`.
- Add `POST /api/v1/notifications/read-all`.
- Notifications must be scoped to the authenticated user.
- Notification records should support categories `MESSAGE`, `BUB`, `SAFE`, `TETHER`, and `SYSTEM`.
- Safe notifications must not include thumbnails, media URLs, or intimate filenames.
- Untether cleanup from B03 must delete notifications tied to the removed tether.
- The unread count should cap display at `99+` on the frontend but return the real count from the backend.

## Implementation Notes

- Reuse existing notification code if present; the ticket goal is a stable API contract for the mobile top nav.
- Include `createdAt`, `readAt`, `category`, `title`, `body`, and optional `linkPath` in list DTOs.
- Generate notifications from existing message/Bub/Safe write paths only if the app already stores notifications; otherwise seed support can be limited to records created by those services in this ticket.

## Tests Or Verification

- Integration test unread summary returns only the authenticated user's unread count.
- Integration test marking one notification read updates summary.
- Integration test read-all marks only the authenticated user's notifications.
- Integration test Safe notification response excludes media URLs.
- Run `cd apps/backend && ./mvnw -Dtest=NotificationControllerIntegrationTest test`.

## Done Criteria

- Mobile can render a top-nav badge and notification list from backend APIs.
- Notification records tied to deleted tethers do not survive untether cleanup.
