# B02 Message Send History And Replies

## Goal

Implement sending messages, loading chat history, and preserving reply context for tethered users.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/controller/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/repository/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Implement `GET /api/v1/chat/thread` for the authenticated user's active tether.
- Implement `POST /api/v1/chat/messages` for text, emoji, and GIF messages.
- Validate text messages:
  - body is required
  - body is trimmed
  - blank text is rejected
- Validate emoji messages:
  - body is required
  - body may contain emoji-only content
  - blank emoji content is rejected
- Validate GIF messages:
  - GIF URL or provider id is required
  - arbitrary blank GIF payloads are rejected
- Support optional `replyToMessageId` when sending a message.
- Reject replies to messages outside the authenticated user's active tether.
- Return thread messages in chronological order by default.
- Exclude messages deleted for the requesting user.
- For messages deleted for everyone, return a stable tombstone response instead of the original message body or GIF payload.
- Include reply preview data in `ChatMessageResponse`:
  - replied-to message id
  - replied-to sender id
  - replied-to display snippet
  - deleted/tombstone state if the replied-to message was deleted for everyone
- Mutating endpoints must reject users without an active tether.

## Implementation Notes

- Keep controller methods thin and put authorization, validation, and tether scoping in the service layer.
- Use existing exception types and HTTP status conventions from `tether` and `home`.
- Apply an initial page size or limit even if cursor pagination is deferred; document response ordering in the DTO or controller test.
- A sent message should start in a Delivered-capable state for the partner, even if Seen is not yet set.

## Tests Or Verification

- Add service/controller tests for:
  - send text message
  - send emoji message
  - send GIF message
  - reject blank text and missing GIF payloads
  - reject send when no active tether exists
  - load chronological thread history
  - reply to a message in the same tether
  - reject reply to another tether's message
  - hide messages deleted for the requester
  - return tombstones for messages deleted for everyone
- Run:

```bash
./mvnw test
```

## Done Criteria

- Tethered users can send text, emoji, and GIF messages through the backend.
- Chat history returns message and reply context needed by mobile.
- Unauthorized and untethered chat access is blocked.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
