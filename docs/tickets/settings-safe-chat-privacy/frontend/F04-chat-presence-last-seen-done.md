# F04 Chat Presence Last Seen

Status: Done

## Goal

Remove stale last-seen copy below the chat profile when the partner has been offline for more than one full day.

## Files To Create Or Modify

- Modify `apps/mobile/lib/src/features/chat/chat_section.dart`
- Modify `apps/mobile/test/chat_screen_test.dart`

## Requirements

- If partner is online, keep the current online indicator.
- If partner is offline for less than or equal to 24 hours, keep concise last-seen copy.
- If partner has been offline for more than 24 hours, do not render last-seen text below the profile.
- Do not hide the partner name, avatar, nickname editor, or other header controls.
- Use the client clock only for display hiding; backend presence semantics should remain unchanged.

## Implementation Notes

- Implement a helper such as `bool shouldShowLastSeen(DateTime? lastSeenAt, DateTime now)`.
- Treat missing `lastSeenAt` as hidden.
- Add a clock injection or helper parameter in tests so boundary behavior is deterministic.

## Tests Or Verification

- Widget test online presence still renders.
- Widget test offline 3 hours ago renders last-seen copy.
- Widget test offline exactly 24 hours ago renders last-seen copy.
- Widget test offline 25 hours ago hides last-seen copy.
- Run `cd apps/mobile && flutter test test/chat_screen_test.dart`.

## Done Criteria

- Chat header no longer shows stale last-seen copy after more than one day offline.

## Implementation Summary

- Added `shouldShowLastSeen(lastSeenAt, now)` and a chat presence clock provider for deterministic tests.
- Chat header still renders `Online` for online partners.
- Chat header renders concise `Last seen HH:mm` copy only when the partner was seen within the last 24 hours, including exactly 24 hours.
- Chat header hides stale/missing offline presence copy after more than 24 hours without hiding the partner name or header actions.

## Verification

- `cd apps/mobile && flutter test test/chat_screen_test.dart --plain-name "presence"`
