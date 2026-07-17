# B01 Bub Domain And Contract

## Goal

Add the persistent Bub event model and public API contract needed to send a Bub from the mobile nav.

## Files To Create Or Modify

- `apps/backend/src/main/resources/db/migration/`
- `apps/backend/src/main/java/com/vencentdev/backend/modules/bub/`
- `packages/api-types/openapi.json`
- `apps/mobile/lib/src/api/generated/`
- backend tests under `apps/backend/src/test/`

## Requirements

- Create a `bub_events` table with:
  - `id UUID PRIMARY KEY`
  - `tether_connection_id UUID NOT NULL REFERENCES tether_connections(id) ON DELETE CASCADE`
  - `sender_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE`
  - `receiver_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE`
  - `created_at TIMESTAMPTZ NOT NULL`
- Add indexes for:
  - latest events by tether connection and timestamp
  - latest events by tether connection plus sender
  - receiver notification lookup if notification delivery is implemented later
- Add a check constraint so `sender_user_id <> receiver_user_id`.
- Create a `BubEvent` JPA entity and `BubEventRepository`.
- Add `POST /api/v1/bubs` for authenticated users.
- Define `BubSendResponse` with:
  - `bubId`
  - `tetherConnectionId`
  - `senderUserId`
  - `receiverUserId`
  - `sentAt`
- The endpoint must require an active tether. Untethered users should receive a clear conflict or bad-request error matching existing project conventions.
- Regenerate OpenAPI and mobile API types after the endpoint is available.

## Implementation Notes

- Put Bub classes under a new `modules/bub` package to avoid expanding Home with write-side Bub behavior.
- Use the existing `TetherConnectionRepository.findActiveByUserId` pattern to resolve the active connection.
- Use the same timestamp source style as current services; if a service-level `Clock` is used, make it injectable for tests.
- Keep notification and vibration delivery out of this ticket unless the backend already has a push-notification abstraction. This ticket must store the event and return a response that a notification worker can use later.

## Tests Or Verification

- Add backend tests for:
  - tethered user can send a Bub
  - stored event references the active tether, sender, receiver, and timestamp
  - untethered user cannot send a Bub
  - self-send is impossible through normal active tether resolution
- Run:

```bash
./mvnw test
```

## Done Criteria

- `bub_events` migration, entity, repository, controller, service, and DTO compile.
- `POST /api/v1/bubs` appears in OpenAPI.
- Generated mobile API types include `BubSendResponse` and the Bub client operation.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
