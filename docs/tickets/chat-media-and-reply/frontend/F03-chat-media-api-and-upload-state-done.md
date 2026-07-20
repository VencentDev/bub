# F03 Chat Media API And Upload State

## Goal

Wire quick image/video selection to the generated backend media upload API with clear upload state.

## Files To Create Or Modify

- Modify: `apps/mobile/pubspec.yaml`
- Modify: `apps/mobile/pubspec.lock`
- Modify: `apps/mobile/lib/src/api/generated/`
- Modify: `apps/mobile/lib/src/features/chat/chat_controller.dart`
- Modify: `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify: `apps/mobile/test/chat_screen_test.dart`

## Requirements

- Regenerate mobile API models after B02:
  - `ChatAttachmentResponse`
  - `ChatMessageResponse.attachments`
  - `uploadChatMediaMessage`
- Use existing `image_picker` for:
  - `pickMultiImage()` for Quick image
  - `pickVideo(source: ImageSource.gallery)` for Quick video
- Add a `ChatThreadController.uploadMedia` method that accepts selected file paths and optional `replyToMessageId`.
- Build multipart requests through the generated client if it supports multipart. If generated multipart support is insufficient, add a focused Dio call inside `ChatThreadController` that uses the existing authenticated `dioProvider`.
- Show upload state without blanking the thread:
  - disable attachment button while uploading
  - show a small progress affordance near the composer
  - keep existing messages visible
  - refresh the thread after upload
- Preserve reply behavior when uploading media from a reply state.
- Clear reply state after successful quick upload.

## Implementation Notes

- Do not store local filesystem paths as chat messages.
- Keep upload failures non-blocking:
  - close picker sheets
  - show a short error near the composer or snackbar
  - keep the composer usable
- If adding a video player dependency is deferred to F04, this ticket should only upload and refresh.
- Suggested controller signature:

```dart
Future<void> uploadMedia({
  required List<String> paths,
  String? replyToMessageId,
});
```

- Suggested upload state:

```dart
final chatMediaUploadProvider =
    AutoDisposeAsyncNotifierProvider<ChatMediaUploadController, void>(
  ChatMediaUploadController.new,
);
```

Use a separate provider only if it avoids overloading `ChatThreadController.state`; otherwise keep a private `_uploadingMedia` boolean in `ChatSection`.

## Tests Or Verification

- Add unit/widget tests for:
  - Quick image calls media upload with selected image paths
  - Quick video calls media upload with selected video path
  - upload progress does not remove existing messages
  - upload failure leaves composer usable
  - reply target is passed to upload and cleared after success
- Use fakes for picker and upload behavior. Introduce injectable picker functions if needed so tests do not touch platform channels.
- Run:

```bash
flutter pub get
flutter test test/chat_screen_test.dart
flutter analyze
```

## Done Criteria

- Quick image/video selection uploads through the backend.
- Existing thread remains visible during upload.
- Errors are visible and recoverable.
- Reply metadata is passed with media upload.
- Changes are committed with a focused message for this ticket.
