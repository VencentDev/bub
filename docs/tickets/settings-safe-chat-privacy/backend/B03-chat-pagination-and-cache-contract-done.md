# B03 Chat Pagination And Cache Contract

## Goal

Change chat loading so the app can fetch recent messages quickly and load older messages when the user back-reads or jumps near a date.

## Files To Create Or Modify

- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/controller/ChatController.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatService.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/ChatServiceImpl.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/repository/ChatMessageRepository.java`
- Modify `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/ChatThreadResponse.java`
- Create DTOs for chat page cursors if the current response cannot carry them cleanly.
- Modify `apps/backend/src/test/java/com/vencentdev/backend/modules/chat/controller/ChatControllerIntegrationTest.java`

## Requirements

- Default thread load returns only the most recent page, recommended limit 50 messages.
- Support `beforeMessageId` or `beforeCreatedAt` for loading older messages.
- Support `aroundDate=YYYY-MM-DD` for date-based back-reading when the user jumps to a date.
- Response includes `hasMoreBefore` and `oldestCursor` so the mobile app can request the next older page.
- Preserve existing live chat, typing, presence, read receipts, replies, reactions, Safe notices, and local pending message behavior.
- Message ordering in each response must remain chronological for rendering.
- Backend must enforce a max page size, recommended 100 messages.

## Implementation Notes

- Keep `GET /api/v1/chat/thread` backward compatible if possible by adding optional query parameters and fields.
- Fetch newest rows in descending order for performance, then reverse to chronological order before returning.
- Add repository indexes or confirm existing indexes for `(tether_connection_id, created_at, id)`.
- Date-based loading should return the closest page before/around the requested local date in the user's configured day zone if available; otherwise use UTC consistently and document it in DTO comments.

## Tests Or Verification

- Integration test default thread returns only the latest page and `hasMoreBefore=true` when older rows exist.
- Integration test older-page query returns the next older messages without overlap.
- Integration test around-date query returns messages near the requested date.
- Integration test untethered user still receives the explicit empty state and cannot page old tether data.
- Run `cd apps/backend && ./mvnw -Dtest=ChatControllerIntegrationTest test`.

## Done Criteria

- Mobile can implement recent chat cache and older-message loading without fetching the entire conversation.
- Existing chat tests still pass after DTO generation.
