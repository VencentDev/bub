# F07 Chat And Image Caching

Status: Done

## Goal

Cache recent chat messages and media images locally so recent chats open quickly and images do not reload every login.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/chat/chat_controller.dart`
- Modify `apps/mobile/lib/src/features/chat/chat_section.dart`
- Create `apps/mobile/lib/src/features/chat/chat_cache_store.dart`
- Create or modify image cache helpers under `apps/mobile/lib/src/core/`
- Modify `apps/mobile/test/chat_screen_test.dart`
- Create `apps/mobile/test/chat_cache_store_test.dart`

## Requirements

- Cache only recent chat pages, recommended latest 50 messages per active tether.
- Cache key must include authenticated user id and active tether id.
- Clear cached chat and images for a tether immediately after untether.
- Use backend pagination from `backend/B03-chat-pagination-and-cache-contract.md` to load older messages when the user scrolls near the oldest cached message.
- Support date-based back-reading by requesting the backend around the selected date.
- Render cached recent messages immediately while refreshing in the background.
- Use Flutter image caching or `cached_network_image` if the project accepts the dependency.
- Cached images must respect URL changes and must not show old tether media after untether.

## Implementation Notes

- Keep cache metadata small: message id, createdAt, type, body, sender, delivery, attachments, and cursors.
- Do not cache raw Safe media thumbnails if backend policy says Safe notifications/media should stay private.
- If adding `cached_network_image`, update `pubspec.yaml` and run `flutter pub get`.
- Add a provider method such as `loadOlder()` in `ChatController` that reads `oldestCursor` from state.

## Tests Or Verification

- Unit test cache returns only records for the active user/tether pair.
- Unit test cache clear removes records for removed tether.
- Widget test chat renders cached recent messages during refresh loading.
- Widget test scrolling near top calls `loadOlder`.
- Run `cd apps/mobile && flutter analyze`.
- Run `cd apps/mobile && flutter test`.

## Done Criteria

- Opening chat no longer waits for a full conversation fetch when cached recent messages exist.
- Older messages still load on demand without duplicate rows.

## Implementation Summary

- Added `ChatCacheStore` with secure-storage persistence and an in-memory test store.
- Cached threads are scoped by authenticated user id and active tether id.
- Cached message history is capped to the latest 50 messages.
- `ChatThreadController` renders cached recent messages immediately, refreshes in the background, supports `loadOlder()`, and supports date-based back-reading through the B03 query contract.
- Chat scroll now requests older messages near the oldest rendered edge.
- Untether cleanup clears the active chat cache and evicts cached network image URLs for the removed tether.
- Image caching uses Flutter's built-in `Image.network`/`NetworkImage` cache, with explicit eviction on tether removal.

## Verification

- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test test/chat_controller_cache_test.dart test/chat_cache_store_test.dart test/chat_screen_test.dart`
