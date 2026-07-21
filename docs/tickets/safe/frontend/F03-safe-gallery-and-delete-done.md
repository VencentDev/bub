# F03 Safe Gallery And Delete

## Goal

Build the unlocked Safe gallery so users can browse vault media sorted by recent and delete Safe photos or videos after confirmation.

## Files To Create Or Modify

- Modify: `apps/mobile/lib/src/features/safe/safe_screen.dart`
- Create: `apps/mobile/lib/src/features/safe/widgets/safe_gallery_grid.dart`
- Create: `apps/mobile/lib/src/features/safe/widgets/safe_media_viewer.dart`
- Create: `apps/mobile/lib/src/features/safe/widgets/safe_delete_confirmation.dart`
- Modify: `apps/mobile/lib/src/features/safe/safe_controller.dart`
- Modify: `apps/mobile/test/safe_screen_test.dart`

## Requirements

- Unlocked Safe state lists Safe media from the backend.
- Sort display by newest first using backend order; do not locally reverse unless the API contract changes.
- Show image thumbnails for image items.
- Show clear video cards or thumbnails for video items.
- Empty gallery should be calm and useful, without exposing private-media copy on the lock screen.
- Tapping a media item opens a full-screen viewer.
- Viewer supports moving between items in the currently loaded gallery.
- Deleting an item requires an explicit confirmation dialog or sheet.
- Confirmation copy should identify the destructive action without showing raw storage paths or IDs.
- After delete succeeds, remove the item from the local gallery.
- If delete fails, keep the item visible and show a recoverable error.
- Do not allow gallery list, viewer, or delete actions while Safe is locked.

## Implementation Notes

- Reuse media rendering patterns from chat image/video viewer where possible.
- Use stable keys:
  - `safe-gallery-grid`
  - `safe-gallery-item-{id}`
  - `safe-media-viewer`
  - `safe-delete-action`
  - `safe-delete-confirm`
  - `safe-delete-cancel`
- Keep fixed aspect ratios for gallery cells to prevent layout shifts during thumbnail load.
- Avoid nested cards; the gallery should feel like a protected tool surface, not a marketing page.

## Tests Or Verification

- Add widget tests for:
  - unlocked state renders `safe-gallery-grid`
  - items render in newest-first order
  - tapping an item opens `safe-media-viewer`
  - delete action opens confirmation
  - cancel keeps the item
  - confirm removes the item after successful API response
  - delete failure keeps the item and shows an error
- Run:

```bash
flutter test test/safe_screen_test.dart
flutter analyze
```

## Done Criteria

- Safe gallery renders only after unlock.
- Gallery is recent-first.
- Media viewer and confirmed deletion work.
- Tests cover success and failure paths.
- Changes are committed with a focused message for this ticket.
