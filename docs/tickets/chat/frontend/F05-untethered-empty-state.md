# F05 Untethered Empty State

## Goal

Render the requested cute Chat empty state for users who do not have a tethered account, and prevent message sending.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/chat/`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/test/`

## Requirements

- Detect the untethered chat state from the chat provider or auth/tether status.
- Render an empty state that fills the Chat section page.
- Use `assets/onboarding/tether.png` as the primary visual and size it to cover the empty state screen.
- Center copy over or within the empty state that says something close to `Tether someone to start your conversation`.
- Do not render the message composer for untethered users.
- Do not allow send, edit, delete, reply, reaction, typing, read receipt, or presence API calls in the untethered state.
- Provide a clear action to start tethering if the existing onboarding route can be reused from Home.
- Keep the bottom navigation visible and usable.
- Ensure the empty state works in light and dark themes.

## Implementation Notes

- Reuse existing tether onboarding entry behavior from the Home partner CTA when possible.
- The epic says `tether.png` should cover the whole chat section page as the empty state screen; use responsive constraints so the image fills without distorting important content.
- Keep the centered copy readable over the image in both themes.
- Avoid adding new assets unless the existing `assets/onboarding/tether.png` is unsuitable.

## Tests Or Verification

- Add widget tests for:
  - untethered Chat renders `assets/onboarding/tether.png`
  - centered empty-state copy is visible
  - composer is absent
  - no chat mutation API is called while untethered
  - tether action routes to the tether onboarding entry screen when available
  - bottom navigation remains visible
  - empty state renders under dark theme
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Untethered users see the requested Chat empty state and cannot send messages.
- The empty state uses `assets/onboarding/tether.png`.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
