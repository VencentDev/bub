# B04 Chat Read Typing And Presence

## Goal

Implement backend support for Delivered, Seen, Typing, Online, Offline, and Last seen chat state.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/controller/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/service/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/repository/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/dto/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Include per-message delivery/read state in `ChatMessageResponse` for messages sent by the authenticated user.
- Show Delivered for partner-visible sent messages that have not been seen.
- Show Seen once the partner marks the message as read.
- Implement `POST /api/v1/chat/read` or equivalent to mark partner messages as seen up to a message id or timestamp.
- Ensure a user cannot mark their own sent messages as seen on behalf of the partner.
- Implement typing state:
  - authenticated user can set typing active/inactive for the active tether
  - typing state expires automatically after a short timeout if not refreshed
  - partner can read whether to show `Typing...`
- Implement presence state:
  - authenticated user activity updates `lastSeenAt`
  - partner presence response can return Online, Offline, and Last seen
  - Online should be time-window based rather than requiring a persistent socket
- Expose a single lightweight state endpoint for mobile polling, such as `GET /api/v1/chat/state`, containing partner typing, partner presence, and latest read state.
- Untethered users must receive no-active-tether behavior consistent with earlier chat endpoints.

## Implementation Notes

- Keep timeout durations as named constants or configuration values so tests can verify edge cases.
- The first implementation may be REST polling based. Do not require a long-lived connection unless the project already has one when implementation starts.
- Treat read receipts and presence as private to the two users in the active tether.
- Avoid leaking exact activity for non-partners.

## Tests Or Verification

- Add tests for:
  - sent message shows Delivered before partner read
  - sent message shows Seen after partner read
  - user cannot mark own message seen as partner
  - typing active appears for partner
  - typing expires after timeout
  - presence returns Online within the online window
  - presence returns Offline or Last seen outside the online window
  - users outside the tether cannot read chat state
- Run:

```bash
./mvnw test
```

## Done Criteria

- Backend exposes read receipt, typing, and presence state needed by mobile.
- Privacy and active tether scoping are covered by tests.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
