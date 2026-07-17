# F03 Message Actions Replies And Reactions

## Goal

Add mobile interactions for editing, deleting, replying to, and reacting to chat messages.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/chat/`
- `apps/mobile/test/`

## Requirements

- Add message action affordances for eligible messages.
- Allow editing the viewer's own message while the backend reports it is editable.
- Do not show edit as available after the 10-minute edit window.
- Submit edits through the generated edit-message API.
- Show edited state on edited messages.
- Add delete for me for any visible message.
- Add delete for everyone only for the viewer's own messages when backend eligibility allows it.
- Confirm delete-for-everyone before sending the API request.
- Render deleted-for-everyone messages as tombstones after mutation.
- Allow replying to a specific message.
- Show reply preview above the composer while composing a reply.
- Include `replyToMessageId` when sending a reply.
- Render reply context on messages that have a reply target.
- Add reaction picker with exactly `❤️`, `😂`, `🥺`, `😭`, and `🔥`.
- Allow adding, replacing, and removing the viewer reaction through the generated reaction APIs.
- Show reaction counts or compact reaction chips on message bubbles.

## Implementation Notes

- Prefer modal bottom sheets or compact menus for message actions on mobile.
- Keep backend business rules authoritative; use response fields to decide which actions to show when available.
- Keep reaction symbols in one shared constant so tests and widgets cannot drift.
- Avoid relying on long-press only; provide an accessible tap target for actions where practical.

## Tests Or Verification

- Add widget tests for:
  - edit action appears for editable own recent message
  - edit action is absent after the edit window
  - edited message shows edited state
  - delete for me removes the message from the local thread after success
  - delete for everyone requires confirmation
  - reply preview appears and is included in send request
  - reply context renders in the thread
  - reaction picker contains only supported reactions
  - add, replace, and remove reaction call the correct APIs
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Epic 5 edit, delete, reply, and reaction mobile interactions are implemented.
- Interaction eligibility is covered by widget tests.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
