# F02 Partner Card

## Goal

Render the Home partner/tether card for both tethered and untethered users.

## Files To Create Or Modify

- `apps/mobile/lib/src/features/home/home_screen.dart`
- `apps/mobile/lib/src/features/home/widgets/home_partner_card.dart`
- `apps/mobile/lib/src/features/tether_onboarding/tether_onboarding_screens.dart`
- `apps/mobile/test/`

## Requirements

- Tethered state:
  - Show viewer and partner profile pictures or fallback initials.
  - Connect the two profiles with a red string visual.
  - Show `Tethered since <date>`.
- Untethered state:
  - Show `assets/illustrations/bears/bear1.png` on the left side of the card.
  - Show copy that encourages the user to tether with someone.
  - Show a `Tether with someone` button.
  - Button routes to the tether onboarding entry screen.
- Card should fit mobile widths without text overflow.
- Keep the card visual style consistent with the glass/floating bottom nav direction.

## Implementation Notes

- Add a focused `HomePartnerCard` widget rather than expanding `home_screen.dart`.
- Use generated dashboard response fields from `F01-home-dashboard-state-and-client.md`.
- If profile image URLs are absent, render initials/fallback circles.
- Use `MaterialPageRoute` or the existing routing pattern to open `EnterTetherScreen`.

## Tests Or Verification

- Add widget tests for:
  - tethered card shows two profile nodes and tethered-since copy
  - untethered card shows `bear1.png`
  - tapping `Tether with someone` opens tether onboarding entry
  - long partner names do not overflow by asserting text uses `maxLines` and ellipsis
- Run:

```bash
flutter test
flutter analyze
```

## Done Criteria

- Partner card handles tethered and untethered dashboard states.
- Untethered CTA routes to onboarding.
- Mobile tests and analyzer pass.
- Changes are committed with a focused message for this ticket.
