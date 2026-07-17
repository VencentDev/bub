# F02 Thread And Composer

## Goal

Render the chat thread and composer so tethered users can send text, emoji, and GIF messages.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/chat/`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/test/`

## Requirements

- Render a chat header area for the partner name and status placeholder.
- Render message bubbles for:
  - viewer messages
  - partner messages
  - text messages
  - emoji messages
  - GIF messages
  - deleted-for-everyone tombstones
- Render message timestamps where useful without cluttering every bubble.
- Add a composer with:
  - text input
  - emoji entry support
  - GIF action
  - send button
- Disable send while the send request is in progress.
- Reject blank sends in the UI before calling the API.
- Call the send-message API for text, emoji, and GIF payloads.
- Append or refresh the sent message after the API succeeds.
- Show an inline send failure state with a retry path.
- Keep the composer hidden or disabled when the user is not tethered; the full untethered design is handled by `F05-untethered-empty-state.md`.

## Implementation Notes

- Keep message bubble, thread list, and composer as separate widgets.
- Use stable keys for critical UI controls and message rows to support widget tests.
- If a full GIF picker provider is not available, implement a minimal URL/provider-id selection seam and leave provider integration for a later ticket, while still sending valid GIF payloads through the API.
- Avoid decorative card nesting inside the chat page; the chat section should feel like a direct conversation surface.

## Tests Or Verification

- Add widget tests for:
  - text, emoji, and GIF messages render correctly
  - viewer and partner bubbles use distinct alignment or styling
  - blank text send does not call the API
  - valid text send calls the API and clears the input
  - send button disables while sending
  - send failure shows retry UI
  - deleted-for-everyone message renders as a tombstone
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Tethered users can send text, emoji, and GIF messages from mobile.
- Thread UI renders the message types returned by the backend.
- Composer behavior is covered by widget tests.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
