# F04 Live State Indicators

## Goal

Show typing, delivery, read, online, offline, and last-seen state in the mobile Chat section.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/chat/`
- `apps/mobile/test/`

## Requirements

- Poll or refresh the backend chat state endpoint for:
  - partner typing state
  - partner presence state
  - latest read receipt state
- Show `Typing...` when the partner typing state is active.
- Hide `Typing...` when typing expires or the partner stops typing.
- Send typing active updates while the viewer is composing.
- Send typing inactive when the composer is cleared, message is sent, or the Chat section is left.
- Mark visible partner messages as seen when the Chat section is open.
- Show Delivered for sent messages that have reached the partner but are not seen.
- Show Seen for sent messages after the partner read state includes them.
- Show Online in the chat header when the partner is online.
- Show Offline or Last seen in the chat header when the partner is not online.
- Avoid showing live state controls in the untethered empty state.

## Implementation Notes

- Use timers carefully and cancel them in provider/widget disposal.
- Keep polling intervals conservative to avoid unnecessary battery and network use.
- Centralize formatting for Last seen copy so tests can cover exact output.
- Do not block sending messages if presence or typing refresh fails; show thread state independently.

## Tests Or Verification

- Add widget/provider tests for:
  - partner typing state renders `Typing...`
  - typing indicator disappears when state becomes inactive
  - typing active is sent while composing
  - typing inactive is sent on send or leaving Chat
  - opening Chat marks partner messages seen
  - Delivered and Seen labels render for sent messages
  - Online, Offline, and Last seen header states render
  - timers are disposed without additional API calls after leaving Chat
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Chat shows the live state called out in Epic 5.
- Timer-based updates are tested and disposed safely.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
