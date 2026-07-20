# F04 Media Message Rendering And Viewer

## Goal

Render quick image/video chat messages and add a swipeable full-screen image viewer for grouped images.

## Files To Create Or Modify

- Modify: `apps/mobile/pubspec.yaml`
- Modify: `apps/mobile/pubspec.lock`
- Modify: `apps/mobile/lib/src/features/chat/chat_section.dart`
- Create if needed: `apps/mobile/lib/src/features/chat/chat_media_viewer.dart`
- Modify: `apps/mobile/test/chat_screen_test.dart`

## Requirements

- Render media messages using `ChatMessageResponse.attachments`.
- Image rendering:
  - one image displays as a rounded media bubble
  - multiple images display as gently spread stacked cards
  - stacked image cards should use subtle rotations or offsets, not large fan-out
  - tapping a single image or stack opens a full-screen viewer
  - full-screen viewer uses horizontal swipe navigation
- Video rendering:
  - each video message displays separately
  - show a rounded video card with a play icon overlay
  - use `video_player` if playback is implemented in this ticket
  - if playback is not implemented in this ticket, tapping the video should open a route with a clear play-ready surface and no broken controls
- Media reply snippets:
  - `Photo`
  - `{count} photos`
  - `Video`
- Deleted media messages:
  - show `This message was deleted`
  - do not show attachments
  - do not show reactions
- Keep reaction badges floating at the bubble corner for non-deleted media messages.

## Implementation Notes

- Prefer a small extracted widget file if `chat_section.dart` becomes hard to scan:

```text
apps/mobile/lib/src/features/chat/chat_media_viewer.dart
```

- Suggested keys:
  - `chat-media-image-{messageId}`
  - `chat-media-image-stack-{messageId}`
  - `chat-media-video-{messageId}`
  - `chat-media-viewer`
  - `chat-media-viewer-page-{index}`
  - `chat-media-play-{messageId}`
- Use stable dimensions to prevent layout jumps:
  - image card max width around `260`
  - image card aspect ratio `4 / 5` or based on attachment metadata if available
  - video card aspect ratio `16 / 9`
- Use `Hero` animation only if it does not complicate tests or cause layout instability.

## Tests Or Verification

- Add widget tests for:
  - one image message renders a media bubble
  - multiple image attachments render one stacked card group
  - tapping the image stack opens `chat-media-viewer`
  - swiping the viewer changes pages
  - video messages render as separate cards
  - deleted media hides attachment cards and reactions
  - media reactions still float outside the card
- Run:

```bash
flutter pub get
flutter test test/chat_screen_test.dart
flutter analyze
```

## Done Criteria

- Image and video messages render in chat.
- Multi-image messages show a stacked-card preview and swipeable viewer.
- Videos display as separate cards.
- Deleted media hides attachments and reactions.
- Changes are committed with a focused message for this ticket.
