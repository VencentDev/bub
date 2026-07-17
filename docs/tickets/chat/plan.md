# Chat Plan

## Feature Goal

Build the couple's private chat space. Tethered users should be able to send, edit, delete, reply to, and react to messages, while also seeing typing, delivery, read, online, offline, and last-seen state. Untethered users should see a cute empty state and cannot send messages yet.

This plan implements Epic 5: Chat, covering US-017 through US-024 and the untethered chat empty state from `docs/product/epics/epic-05-chat.md`.

## Architecture Summary

Backend owns chat persistence, authorization, message mutation rules, read/delivery state, typing state, and presence state. Chat data should be scoped to the authenticated user's active tether so users can only access their own couple conversation.

Mobile adds a real Chat section to the authenticated shell. It should use generated API types and Riverpod state, render the conversation thread and composer, and keep Home, Bub, Safe, and Settings navigation working while chat data loads or errors. Because the codebase does not yet have a socket layer, the first ticket set should use REST-backed state with short polling or refresh hooks where live state is needed; a future realtime transport can replace that without changing the core UI contract.

## Frontend Ticket List

- `frontend/F01-chat-state-and-client.md`
- `frontend/F02-thread-and-composer.md`
- `frontend/F03-message-actions-replies-and-reactions.md`
- `frontend/F04-live-state-indicators.md`
- `frontend/F05-untethered-empty-state.md`

## Backend Ticket List

- `backend/B01-chat-schema-and-contract.md`
- `backend/B02-message-send-history-and-replies.md`
- `backend/B03-message-edits-deletes-and-reactions.md`
- `backend/B04-chat-read-typing-and-presence.md`

## Implementation Order

1. `backend/B01-chat-schema-and-contract.md`
2. `backend/B02-message-send-history-and-replies.md`
3. `backend/B03-message-edits-deletes-and-reactions.md`
4. `backend/B04-chat-read-typing-and-presence.md`
5. `frontend/F01-chat-state-and-client.md`
6. `frontend/F02-thread-and-composer.md`
7. `frontend/F03-message-actions-replies-and-reactions.md`
8. `frontend/F04-live-state-indicators.md`
9. `frontend/F05-untethered-empty-state.md`

## Acceptance Criteria

- Tethered users can send text messages.
- Tethered users can send emoji messages.
- Tethered users can send GIF messages.
- Users can edit their own message within 10 minutes.
- Users cannot edit a message after the 10-minute edit window.
- Users can delete a message for themselves.
- Users can delete their own message for everyone.
- Users can reply to a specific message and see the reply context in the thread.
- Users can react to messages with `❤️`, `😂`, `🥺`, `😭`, and `🔥`.
- The chat shows `Typing...` when the partner is actively typing.
- Sent messages show Delivered and Seen states.
- The chat header shows Online, Offline, and Last seen states for the partner.
- Untethered users see an empty state screen, cannot send a message, and see `assets/onboarding/tether.png` covering the chat section page.
- The untethered empty state includes centered copy similar to `Tether someone to start your conversation`.

## Verification Commands

Run these from `apps/backend` for backend tickets:

```bash
./mvnw test
```

Run these from `apps/mobile` for frontend tickets:

```bash
flutter analyze
flutter test
```

Run the relevant narrower test command first while implementing a single ticket, then run the full command set before committing that ticket's work.

## Commit Policy

- Commit automatically after each coherent ticket or file-change batch.
- Stage only files changed for the completed ticket or batch.
- Use a focused commit message that names the implemented ticket, such as `feat: implement B01 chat schema`.
- Do not include unrelated dirty work in the commit.
