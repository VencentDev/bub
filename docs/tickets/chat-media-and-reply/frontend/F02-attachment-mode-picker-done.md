# F02 Attachment Mode Picker

## Goal

Add an attachment button beside the emoji button and show a Safe vs Quick picker before file selection.

## Files To Create Or Modify

- Modify: `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify: `apps/mobile/test/chat_screen_test.dart`

## Requirements

- Show an attachment button beside the emoji button when the message field is empty.
- Keep the composer field stable when attachment, emoji, and send buttons appear or disappear.
- Tapping attachment first opens a dialog or bottom sheet with:
  - `Safe`
  - `Quick`
- Safe selection should not open the file picker in this ticket.
- Safe selection should insert a divider-style local row in the chat timeline:
  - `New image added to Safe` when the user chose image intent
  - `New video added to Safe` when the user chose video intent
- Because the first picker only asks Safe vs Quick, ask image/video intent in the next sheet:
  - Safe -> image/video intent -> local divider row
  - Quick -> image/video intent -> picker and upload flow from F03
- Keep the emoji picker back behavior unchanged.

## Implementation Notes

- Add keys:
  - `chat-attachment-button`
  - `chat-attachment-mode-sheet`
  - `chat-attachment-safe-option`
  - `chat-attachment-quick-option`
  - `chat-attachment-kind-sheet`
  - `chat-attachment-image-option`
  - `chat-attachment-video-option`
  - `chat-safe-placeholder-image`
  - `chat-safe-placeholder-video`
- Represent local Safe placeholders with a small private model in `chat_section.dart`, such as:

```dart
class _LocalChatDivider {
  const _LocalChatDivider({required this.id, required this.label});

  final String id;
  final String label;
}
```

- Render the Safe placeholder using the same visual language as `_TimeDivider`, with a short centered label and side lines.
- Keep Safe placeholder local to the current chat screen until Epic 7 Safe has persistence.

## Tests Or Verification

- Add widget tests for:
  - attachment button appears beside emoji button when composer is empty
  - tapping attachment shows the Safe vs Quick sheet
  - choosing Safe image inserts `New image added to Safe`
  - choosing Safe video inserts `New video added to Safe`
  - typing text hides quick action buttons and shows send button
- Run:

```bash
flutter test test/chat_screen_test.dart
flutter analyze
```

## Done Criteria

- Attachment button is visible in the minimal composer.
- Safe vs Quick selection appears before file intent selection.
- Safe image/video selection creates a divider-style local chat row.
- Existing emoji and send behavior remains green.
- Changes are committed with a focused message for this ticket.
