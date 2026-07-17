# F02 First Bub Empty Card

## Goal

Fix the Home Bub card empty state so tethered users are invited to send their first Bub instead of being told to tether.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/widgets/home_latest_bub_card.dart`
- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/test/`

## Requirements

- Untethered users may still see copy that explains tethering is required before sending a Bub.
- Tethered users with no Bub activity must not see `Tether to send bub`.
- Tethered users with no Bub activity should see:
  - primary copy: `Send your first Bub`
  - a button or tappable chip labeled `Send your first Bub`
- The first-Bub button should call a callback supplied by Home. It should not directly know about the floating nav or tutorial implementation.
- Keep the existing Bub artwork and card treatment unless it conflicts with the new button layout.
- The card should remain compact and should not be obscured by the floating nav on small screens.

## Implementation Notes

- Use the dashboard response to distinguish untethered from tethered empty states. If the backend provides `hasActiveTether` only on the tether card, pass that value into `HomeLatestBubCard`.
- Rename widget constructor parameters only where needed and update tests accordingly.
- Keep stable keys for tests:
  - `home-latest-bub-card`
  - `home-latest-bub-art`
  - add `home-first-bub-button`

## Tests Or Verification

- Add widget tests for:
  - untethered no-activity card keeps tether-required messaging
  - tethered no-activity card shows `Send your first Bub`
  - tethered no-activity card does not show `Tether to send bub`
  - tapping `home-first-bub-button` invokes the supplied callback
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Tethered empty Bub card displays the first-send CTA.
- Untethered empty Bub card still points users toward tethering.
- Tests cover both states.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
