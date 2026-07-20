# F01 Reply Preview And Swipe

## Goal

Remove the vertical accent bar from replied-message previews and add swipe-to-reply on every chat message row.

## Files To Create Or Modify

- Modify: `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify: `apps/mobile/test/chat_screen_test.dart`

## Requirements

- Remove the small vertical bar from `_ReplyOverlapPreview`.
- Keep the reply preview visually separate from the bubble background.
- Keep the message bubble background tightly wrapped around the actual message content.
- Add horizontal swipe-to-reply for both viewer and partner messages.
- Swiping right on partner messages and swiping left on viewer messages should both set `_replyTo`.
- The gesture should feel deliberate:
  - track horizontal drag only
  - trigger reply after at least `56` logical pixels of horizontal movement
  - reset the row position after release
- Keep long-press message actions working.
- Do not make normal vertical scrolling harder.

## Implementation Notes

- In `_MessageBubble`, add drag handling around the existing message row:
  - `onHorizontalDragUpdate`
  - `onHorizontalDragEnd`
  - `onHorizontalDragCancel`
- Use a small transient offset for visual feedback while swiping.
- Clamp the visual offset to avoid moving rows too far:

```dart
double _clampedReplyDrag(double delta, bool mine) {
  final direction = mine ? -1 : 1;
  return (delta * direction).clamp(0, 72).toDouble() * direction;
}
```

- Trigger `onReply()` when the absolute drag distance is at least `56`.
- Add a small reply icon that appears while dragging near the leading edge of the swipe direction.
- Keep keys stable:
  - `chat-message-row-{id}`
  - `chat-reply-overlap-{id}`
  - `chat-reply-preview`

## Tests Or Verification

- Add widget tests in `apps/mobile/test/chat_screen_test.dart`:
  - reply overlap renders without the vertical accent bar key
  - swiping a partner message shows `chat-reply-preview`
  - swiping a viewer message shows `chat-reply-preview`
  - long press still opens `chat-message-action-sheet`
- Suggested test assertions:

```dart
expect(find.byKey(const Key('chat-reply-overlap-accent-replying')), findsNothing);
await tester.drag(find.byKey(const Key('chat-message-row-partner')), const Offset(72, 0));
await tester.pumpAndSettle();
expect(find.byKey(const Key('chat-reply-preview')), findsOneWidget);
```

- Run:

```bash
flutter test test/chat_screen_test.dart
flutter analyze
```

## Done Criteria

- Replied-message preview has no vertical bar.
- Swipe-to-reply works for sent and received messages.
- Existing long-press reply still works.
- Chat tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
