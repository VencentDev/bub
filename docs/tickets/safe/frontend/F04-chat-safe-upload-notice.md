# F04 Chat Safe Upload Notice

## Goal

Connect the chat attachment Safe path to real Safe uploads and render `safe-box.png` notices with the count of files added to Safe.

## Files To Create Or Modify

- Modify: `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify: `apps/mobile/lib/src/features/chat/chat_controller.dart`
- Modify: `apps/mobile/lib/src/features/chat/chat_media_picker.dart`
- Modify: `apps/mobile/lib/src/features/safe/safe_controller.dart`
- Modify: `apps/mobile/test/chat_screen_test.dart`
- Modify: `apps/mobile/test/safe_screen_test.dart`

## Requirements

- Choosing Safe in the chat attachment picker should upload the selected files to Safe using Safe endpoints.
- If Safe is locked, prompt for PIN unlock before upload or route to the Safe unlock flow and resume upload only after successful unlock.
- Do not send Safe media through quick chat media endpoints.
- Do not render Safe media thumbnails in chat.
- Render a chat notice using `safe-box.png`.
- Notice text must indicate how many files were added to Safe.
- Use singular and plural copy correctly, for example:
  - `1 file added to Safe`
  - `3 files added to Safe`
- The notice should be associated with the uploader and show in the chat thread for both partners once backend chat notice support exists.
- Pending upload state should not expose local filenames or local file paths.
- Failed Safe upload should show a recoverable error and should not insert a successful notice.
- Existing Quick image/video attachment flow must keep working.

## Implementation Notes

- Replace the current local placeholder notice that says `New media added to Safe`.
- Use `apps/mobile/assets/illustrations/bears/safe-box.png` for the Safe notice visual.
- If backend returns a `SAFE_NOTICE` chat message type, map it in generated models and rendering code.
- Keep local optimistic UI conservative. Prefer a pending safe notice that becomes a real notice after upload succeeds, or wait for the backend response.
- Use stable keys:
  - `chat-safe-notice-{id}`
  - `chat-safe-notice-image`
  - `chat-safe-notice-count`
  - `chat-safe-upload-error`

## Tests Or Verification

- Add widget tests for:
  - selecting Safe prompts unlock when Safe is locked
  - Safe upload calls Safe controller, not quick chat media upload
  - successful one-file upload renders `1 file added to Safe`
  - successful multi-file upload renders plural count
  - notice includes `chat-safe-notice-image`
  - failed upload shows `chat-safe-upload-error`
  - Quick attachment tests still pass
- Run:

```bash
flutter test test/chat_screen_test.dart
flutter test test/safe_screen_test.dart
flutter analyze
```

## Done Criteria

- Chat Safe picker path uploads to Safe.
- Chat notice uses `safe-box.png` and displays file count.
- Private Safe media is never shown in chat.
- Existing Quick attachment behavior still passes tests.
- Changes are committed with a focused message for this ticket.
