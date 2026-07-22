# F03 Top Nav Notifications

## Goal

Add a notification icon and unread badge to the app's top navigation, with a list view for notifications.

## Files To Create Or Modify

- Modify the authenticated home shell in `apps/mobile/lib/src/features/home/home_screen.dart` or the current top-nav owner.
- Create `apps/mobile/lib/src/features/notifications/notification_controller.dart`
- Create `apps/mobile/lib/src/features/notifications/notification_panel.dart`
- Modify generated API files after backend OpenAPI generation.
- Create `apps/mobile/test/notification_panel_test.dart`
- Modify `apps/mobile/test/widget_test.dart`

## Requirements

- Top nav shows a bell icon button.
- Bell shows an unread badge when unread count is greater than zero.
- Badge shows exact counts from 1 to 99 and `99+` above 99.
- Tapping the bell opens a notification panel, sheet, or page.
- Notification list supports loading, empty, error, retry, unread, and read states.
- Tapping a notification marks it read and navigates to the target area when `linkPath` is supported.
- Safe notifications must use private copy and must not render thumbnails.

## Implementation Notes

- Use `Icons.notifications_rounded` or the existing icon system.
- Poll summary when the app returns to foreground if live notification delivery is not available yet.
- Invalidate notification summary after mark-read and read-all actions.
- Keep notification rendering compact because the top nav is an operational app surface, not a marketing page.

## Tests Or Verification

- Widget test bell renders in top nav.
- Widget test unread badge renders `3` and `99+`.
- Widget test empty notification state renders when list is empty.
- Widget test tapping an unread item calls mark-read.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Users can discover and read notifications from the top nav.
- Unread count updates after read actions.
