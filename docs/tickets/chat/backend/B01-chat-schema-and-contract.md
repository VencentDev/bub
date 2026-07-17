# B01 Chat Schema And Contract

## Goal

Define the backend chat persistence model, REST API contract, and generated mobile API types for the couple chat feature.

## Files To Create Or Modify

- `apps/backend/src/main/java/com/vencentdev/backend/modules/chat/`
- backend migration files
- backend tests under `apps/backend/src/test/`
- `packages/api-types/openapi.json`
- `apps/mobile/lib/src/api/generated/`

## Requirements

- Add chat data scoped by active tether connection.
- Add message persistence with:
  - message id
  - tether connection id
  - sender user id
  - message type: `TEXT`, `EMOJI`, or `GIF`
  - text body for text or emoji messages
  - GIF URL or provider id for GIF messages
  - optional reply-to message id
  - created timestamp
  - updated timestamp
  - edited timestamp
  - deleted-for-everyone timestamp
- Add per-user chat deletion state so `delete for me` can hide a message for one participant without deleting it for the partner.
- Add message reactions constrained to `❤️`, `😂`, `🥺`, `😭`, and `🔥`.
- Add delivery/read state that can represent Delivered and Seen for each sent message.
- Add typing and presence state fields needed by `B04-chat-read-typing-and-presence.md`.
- Define DTOs for:
  - `ChatThreadResponse`
  - `ChatMessageResponse`
  - `ChatSendMessageRequest`
  - `ChatEditMessageRequest`
  - `ChatReactionRequest`
  - `ChatTypingRequest`
  - `ChatPresenceResponse`
- Define REST endpoints in OpenAPI for:
  - loading the chat thread
  - sending a message
  - editing a message
  - deleting a message for me
  - deleting a message for everyone
  - adding or replacing a reaction
  - removing a reaction
  - marking messages seen
  - setting typing state
  - reading partner presence
- Untethered users must receive an explicit no-active-tether response or a clear `409 Conflict` for mutating chat endpoints.

## Implementation Notes

- Follow existing module layout patterns from `home` and `tether`.
- Keep all chat access checks based on the authenticated user's active tether.
- Prefer database constraints for immutable ownership rules and reaction uniqueness.
- Keep transport REST-first for this ticket set. Do not introduce WebSocket or SSE infrastructure unless a project-wide realtime pattern already exists when implementation starts.
- Regenerate mobile API types after OpenAPI includes the chat endpoints.

## Tests Or Verification

- Add migration/schema tests or repository tests for:
  - storing text, emoji, and GIF messages
  - reply-to message relationships
  - delete-for-me state per participant
  - unique reaction per user per message
- Add contract tests that verify the OpenAPI-visible request and response shapes.
- Run:

```bash
./mvnw test
```

## Done Criteria

- Chat schema supports every Epic 5 user story without placeholder fields.
- Chat DTOs and endpoints are present in OpenAPI.
- Generated mobile API types include chat models and endpoint methods.
- Backend tests pass.
- Changes are committed with a focused message for this ticket.
