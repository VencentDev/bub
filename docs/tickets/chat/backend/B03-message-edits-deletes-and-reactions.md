# B03 Message Edits Deletes And Reactions

## Goal

Implement message editing, delete-for-me, delete-for-everyone, and supported reactions.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/controller/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/repository/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Implement editing a message owned by the authenticated user.
- Allow editing only within 10 minutes of the message creation timestamp.
- Reject editing after the 10-minute limit.
- Reject editing another user's message.
- Reject editing messages deleted for everyone.
- Preserve `editedAt` and updated body in the thread response.
- Implement delete for me:
  - hides the message only for the authenticated user
  - does not remove the message for the partner
  - works on own and partner messages
- Implement delete for everyone:
  - only the original sender can delete for everyone
  - replaces message content with a tombstone in both participants' thread responses
  - removes or suppresses editable payload fields
- Implement add or replace reaction with only `❤️`, `😂`, `🥺`, `😭`, and `🔥`.
- Implement remove reaction for the authenticated user's own reaction.
- Include reaction summary and current viewer reaction in `ChatMessageResponse`.
- Reject reactions on messages outside the active tether.
- Reject reactions on messages deleted for everyone.

## Implementation Notes

- Use an injectable clock or existing project time abstraction for the 10-minute edit-window tests.
- Store delete-for-everyone as state, not a hard delete, so reply previews and ordering remain stable.
- If the reaction set is represented as an enum, ensure the OpenAPI schema exposes the supported values clearly.

## Tests Or Verification

- Add tests for:
  - edit own recent message succeeds
  - edit own message after 10 minutes fails
  - edit partner message fails
  - edit deleted-for-everyone message fails
  - delete for me hides only from requester
  - delete for everyone returns tombstones to both users
  - sender-only enforcement for delete for everyone
  - add, replace, and remove reaction
  - unsupported reaction is rejected
  - reactions on other-tether messages are rejected
- Run:

```bash
./mvnw test
```

## Done Criteria

- Epic 5 edit, delete, and reaction backend behavior is implemented.
- Message mutation rules are enforced in tests.
- Thread responses expose edited, deleted, and reaction state for mobile.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
