# F06 Untether Warning Copy

## Goal

Update the untether confirmation dialog to clearly warn that couple history and media will be permanently deleted.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/settings/settings_screen.dart`
- Modify `apps/mobile/test/widget_test.dart`

## Requirements

- Dialog title remains direct, for example `Remove tether?`.
- Dialog body must mention permanent deletion of:
  - chat conversation
  - chat images and media
  - Shared Safe
  - shared moments
  - Bub history
  - Bub streak
  - "Been tethered" duration/history
  - other couple history tied to the tether
- Primary destructive button remains `Remove tether`.
- Cancel button remains available and non-destructive.
- The dialog must not imply that the data can be restored.

## Implementation Notes

- Suggested copy:
  `This permanently deletes your chat conversation, images and media, Shared Safe, shared moments, Bub history, Bub streak, "Been tethered" history, and other couple history for this tether. This cannot be undone.`
- Keep the destructive button styled consistently with existing settings actions.

## Tests Or Verification

- Widget test opening the dialog finds the permanent deletion warning.
- Widget test cancel does not call `onRemoveTether`.
- Widget test remove calls `onRemoveTether` once.
- Run `cd apps/mobile && flutter test test/widget_test.dart`.

## Done Criteria

- Users see a clear destructive-data warning before untethering.
