# Chat Media And Reply Plan

## Feature Goal

Polish chat replies to feel Messenger-like, add swipe-to-reply, and add quick image/video chat attachments with a Safe-mode placeholder path for the future Safe feature.

## Architecture Summary

Reply UI stays purely mobile-side: reply previews should overlap above the replied message without the vertical accent bar, and any message row can be swiped horizontally to set the composer reply target. Media sending needs backend support because quick images/videos must be uploaded through the server instead of embedding local file paths in messages. The backend should add a multipart chat media endpoint, store files using a chat-specific storage service modeled after Moment uploads, and return generated API models that the mobile app can render as image stacks or separate video cards.

Safe attachments are intentionally a temporary mobile-only placeholder in this ticket set. Selecting Safe should not upload media yet; it should insert a divider-style local status row in the chat section that says `New image added to Safe` or `New video added to Safe`.

## Epic 5 Gap Review

`docs/product/epics/epic-05-chat.md` currently covers:

- US-017: send text and emoji
- US-018: edit recent message
- US-019: delete for me and delete for everyone
- US-020: reply to a message
- US-021: supported reactions
- US-022: typing indicator
- US-023: delivered and seen receipts
- US-024: online, offline, and last seen
- untethered chat empty state

Missing or changed from the current requested product direction:

- Quick image attachment messages.
- Quick video attachment messages.
- Multiple-image grouped display with a swipeable viewer.
- Video messages displayed as separate cards.
- Attachment mode picker with Safe and Quick choices.
- Temporary Safe placeholder event in chat until the Safe feature exists.
- Swipe-to-reply gesture.
- Messenger-style reply preview without the vertical accent bar.
- Current UI uses check icons for delivery/read instead of literal `Delivered` and `Seen` labels, so Epic 5 should be updated to match the current Telegram/Messenger reference.
- Edit message exists in the epic, but the current long-press action sheet removed Edit. Product needs to decide whether edit remains required or is intentionally deferred.

## Frontend Ticket List

- `frontend/F01-reply-preview-and-swipe.md`
- `frontend/F02-attachment-mode-picker.md`
- `frontend/F03-chat-media-api-and-upload-state.md`
- `frontend/F04-media-message-rendering-and-viewer.md`

## Backend Ticket List

- `backend/B01-chat-media-domain-and-storage.md`
- `backend/B02-chat-media-upload-api.md`

## Docs Ticket List

- `docs/D01-update-chat-epic.md`

## Implementation Order

1. `docs/D01-update-chat-epic.md`
2. `frontend/F01-reply-preview-and-swipe.md`
3. `backend/B01-chat-media-domain-and-storage.md`
4. `backend/B02-chat-media-upload-api.md`
5. Regenerate mobile API client from backend OpenAPI.
6. `frontend/F02-attachment-mode-picker.md`
7. `frontend/F03-chat-media-api-and-upload-state.md`
8. `frontend/F04-media-message-rendering-and-viewer.md`

## Acceptance Criteria

- Reply preview above a replied message no longer displays the vertical `|` accent.
- Reply preview still overlaps the message visually, but the message bubble background only wraps the actual message content.
- Swiping a message row horizontally sets that message as the composer reply target.
- The composer shows an attachment button beside the emoji button when the input is empty.
- Tapping the attachment button first shows a Safe vs Quick picker.
- Choosing Safe does not upload files yet and inserts a divider-style chat row with `New image added to Safe` or `New video added to Safe`.
- Choosing Quick allows the user to pick images or a video and sends them through the backend.
- Multiple selected images render as a gently spread stacked-card media group.
- Tapping an image stack opens a swipeable full-screen image viewer.
- Videos render as separate message cards, even when selected after other media.
- Deleting a media message follows existing chat delete behavior.
- Reactions are not shown on deleted messages.
- Replies to media messages preserve reply context with a useful snippet such as `Photo`, `3 photos`, or `Video`.
- Existing text, emoji, reaction, delivery checks, typing, presence, and untethered empty state behavior still pass tests.

## Verification Commands

Run these from `apps/backend` for backend tickets:

```bash
./mvnw -Dtest=ChatControllerIntegrationTest test
./mvnw spotless:check
```

Run these from `apps/mobile` for frontend tickets:

```bash
flutter pub get
flutter test test/chat_screen_test.dart
flutter test test/widget_test.dart
flutter analyze
```

Run API generation after backend OpenAPI changes:

```bash
dart run swagger_parser
```

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 chat media domain`.
- Do not include unrelated dirty work in the commit.
